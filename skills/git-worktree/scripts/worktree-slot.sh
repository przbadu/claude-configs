#!/usr/bin/env bash
set -euo pipefail

# Worktree Slot Manager
# Manages git worktrees with deterministic port assignment for parallel development.
# Ports: slot N → Rails on 3000+N*10, Vite on 3001+N*10
#
# This script auto-detects po-app and po-app-gfo directories.
# Override with: POAPP_DIR and GFO_DIR environment variables.

# --- Auto-detect project directories ---

detect_poapp_dir() {
  if [ -n "${POAPP_DIR:-}" ]; then
    echo "$POAPP_DIR"
    return
  fi

  # Check if we're inside a po-app repo (main or worktree)
  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "")

  if [ -n "$git_root" ]; then
    # Check if this is a worktree — find the main repo
    local common_dir
    common_dir=$(git rev-parse --git-common-dir 2>/dev/null || echo "")
    if [ -n "$common_dir" ] && [[ "$common_dir" != *".git" ]]; then
      # We're in a worktree, resolve main repo
      local main_repo
      main_repo=$(cd "$common_dir/.." && pwd)
      if [ -f "$main_repo/Gemfile" ] && grep -q "rails" "$main_repo/Gemfile" 2>/dev/null; then
        echo "$main_repo"
        return
      fi
    fi

    # Check if current git root is po-app
    if [ -f "$git_root/Gemfile" ] && grep -q "rails" "$git_root/Gemfile" 2>/dev/null; then
      echo "$git_root"
      return
    fi
  fi

  # Fallback: check common locations
  for dir in ~/projects/pex/po-app ../po-app; do
    if [ -d "$dir" ] && [ -f "$dir/Gemfile" ]; then
      echo "$(cd "$dir" && pwd)"
      return
    fi
  done

  die "Could not find po-app directory. Set POAPP_DIR environment variable."
}

detect_gfo_dir() {
  if [ -n "${GFO_DIR:-}" ]; then
    echo "$GFO_DIR"
    return
  fi

  local poapp="$1"
  for dir in "$poapp/../po-app-gfo" ~/projects/pex/po-app-gfo; do
    if [ -d "$dir" ] && [ -d "$dir/.git" ]; then
      echo "$(cd "$dir" && pwd)"
      return
    fi
  done

  echo ""
}

REGISTRY="${HOME}/.claude/worktree-slots.json"
MAX_SLOTS=5

# --- Helpers ---

die() { echo "Error: $*" >&2; exit 1; }

require_jq() {
  command -v jq >/dev/null 2>&1 || die "jq is required. Install with: brew install jq"
}

ensure_registry() {
  if [ ! -f "$REGISTRY" ]; then
    mkdir -p "$(dirname "$REGISTRY")"
    echo '{"slots":{},"max_slots":5}' > "$REGISTRY"
  fi
}

validate_slot() {
  local slot="$1"
  [[ "$slot" =~ ^[1-5]$ ]] || die "Slot must be 1-$MAX_SLOTS (got: $slot)"
}

slot_taken() {
  local slot="$1"
  jq -e ".slots[\"$slot\"]" "$REGISTRY" >/dev/null 2>&1
}

rails_port() { echo $(( 3000 + $1 * 10 )); }
vite_port()  { echo $(( 3001 + $1 * 10 )); }

sanitize_branch() { echo "$1" | tr '/' '-'; }

is_port_alive() {
  lsof -ti :"$1" >/dev/null 2>&1
}

# --- Subcommands ---

cmd_create() {
  local slot="${1:?Usage: worktree-slot create <slot> <branch>}"
  local branch="${2:?Usage: worktree-slot create <slot> <branch>}"
  validate_slot "$slot"
  ensure_registry

  local POAPP_DIR
  POAPP_DIR=$(detect_poapp_dir)
  local GFO_DIR
  GFO_DIR=$(detect_gfo_dir "$POAPP_DIR")

  slot_taken "$slot" && die "Slot $slot is already in use. Run 'worktree-slot list' to see slots."

  local rp=$(rails_port "$slot")
  local vp=$(vite_port "$slot")
  local safe_branch=$(sanitize_branch "$branch")
  local wt_name="slot-${slot}--${safe_branch}"
  local rails_wt="$POAPP_DIR/.worktrees/$wt_name"
  local gfo_wt=""

  echo "Creating slot $slot for branch '$branch' (Rails:$rp, Vite:$vp)..."

  # Create Rails worktree
  if [ -d "$rails_wt" ]; then
    echo "  Rails worktree already exists at $rails_wt"
  else
    echo "  Creating Rails worktree..."
    git -C "$POAPP_DIR" worktree add "$rails_wt" "$branch" 2>/dev/null \
      || git -C "$POAPP_DIR" worktree add -b "$branch" "$rails_wt" 2>/dev/null \
      || die "Failed to create Rails worktree for branch '$branch'"
  fi

  # Copy and extend application.yml
  local app_yml="$POAPP_DIR/config/application.yml"
  local wt_yml="$rails_wt/config/application.yml"
  if [ -f "$app_yml" ]; then
    cp "$app_yml" "$wt_yml"
    # Remove any previous slot overrides
    sed -i '' '/^# Slot-specific overrides/,$d' "$wt_yml" 2>/dev/null || true
    cat >> "$wt_yml" <<EOF

# Slot-specific overrides (added by worktree-slot)
PORT: "$rp"
APP_HOST: "localhost:$rp"
EOF
    echo "  Configured application.yml (PORT=$rp, APP_HOST=localhost:$rp)"
  else
    echo "  Warning: No config/application.yml found in main repo"
  fi

  # Bundle install in worktree
  echo "  Running bundle install..."
  (cd "$rails_wt" && bundle install --quiet 2>/dev/null) || echo "  Warning: bundle install had issues"

  # Create frontend worktree if po-app-gfo exists
  if [ -n "$GFO_DIR" ] && [ -d "$GFO_DIR/.git" ]; then
    gfo_wt="$GFO_DIR/.worktrees/$wt_name"
    if [ -d "$gfo_wt" ]; then
      echo "  Frontend worktree already exists at $gfo_wt"
    else
      echo "  Creating frontend worktree..."
      if git -C "$GFO_DIR" worktree add "$gfo_wt" "$branch" 2>/dev/null; then
        echo "  Frontend worktree on branch '$branch'"
      elif git -C "$GFO_DIR" worktree add "$gfo_wt" main 2>/dev/null; then
        echo "  Frontend worktree on 'main' (branch '$branch' not found in po-app-gfo)"
      else
        echo "  Warning: Could not create frontend worktree"
        gfo_wt=""
      fi
    fi

    if [ -n "$gfo_wt" ] && [ -d "$gfo_wt" ]; then
      cat > "$gfo_wt/.env.local" <<EOF
VITE_PORT=$vp
VITE_BACKEND_URL=http://localhost:$rp
EOF
      echo "  Configured .env.local (VITE_PORT=$vp, VITE_BACKEND_URL=http://localhost:$rp)"

      echo "  Running npm install..."
      (cd "$gfo_wt" && npm install --silent 2>/dev/null) || echo "  Warning: npm install had issues"
    fi
  else
    echo "  Skipping frontend (po-app-gfo not found)"
  fi

  # Update registry
  local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local tmp=$(mktemp)
  jq --arg slot "$slot" \
     --arg branch "$branch" \
     --argjson rp "$rp" \
     --argjson vp "$vp" \
     --arg rwt "$rails_wt" \
     --arg gwt "${gfo_wt:-}" \
     --arg now "$now" \
     '.slots[$slot] = {
        branch: $branch,
        rails_port: $rp,
        vite_port: $vp,
        rails_worktree: $rwt,
        gfo_worktree: $gwt,
        created_at: $now
      }' "$REGISTRY" > "$tmp" && mv "$tmp" "$REGISTRY"

  echo ""
  echo "Slot $slot created successfully!"
  echo "  Rails:    $rails_wt (port $rp)"
  [ -n "$gfo_wt" ] && echo "  Frontend: $gfo_wt (port $vp)"
  echo ""
  echo "Start servers:"
  echo "  worktree-slot start $slot             # Rails on :$rp"
  [ -n "$gfo_wt" ] && echo "  worktree-slot start $slot --frontend   # Vite on :$vp"
}

cmd_remove() {
  local slot="${1:?Usage: worktree-slot remove <slot>}"
  validate_slot "$slot"
  ensure_registry

  slot_taken "$slot" || die "Slot $slot is not in use"

  local POAPP_DIR
  POAPP_DIR=$(detect_poapp_dir)
  local GFO_DIR
  GFO_DIR=$(detect_gfo_dir "$POAPP_DIR")

  # Stop processes first
  cmd_stop "$slot" 2>/dev/null || true

  local rails_wt=$(jq -r ".slots[\"$slot\"].rails_worktree" "$REGISTRY")
  local gfo_wt=$(jq -r ".slots[\"$slot\"].gfo_worktree // empty" "$REGISTRY")

  # Remove Rails worktree
  if [ -n "$rails_wt" ] && [ -d "$rails_wt" ]; then
    echo "Removing Rails worktree..."
    git -C "$POAPP_DIR" worktree remove "$rails_wt" --force 2>/dev/null || rm -rf "$rails_wt"
  fi
  git -C "$POAPP_DIR" worktree prune 2>/dev/null || true

  # Remove frontend worktree
  if [ -n "$gfo_wt" ] && [ -d "$gfo_wt" ] && [ -n "$GFO_DIR" ]; then
    echo "Removing frontend worktree..."
    git -C "$GFO_DIR" worktree remove "$gfo_wt" --force 2>/dev/null || rm -rf "$gfo_wt"
    git -C "$GFO_DIR" worktree prune 2>/dev/null || true
  fi

  # Update registry
  local tmp=$(mktemp)
  jq "del(.slots[\"$slot\"])" "$REGISTRY" > "$tmp" && mv "$tmp" "$REGISTRY"

  echo "Slot $slot removed."
}

cmd_start() {
  local slot="${1:?Usage: worktree-slot start <slot> [--frontend]}"
  local frontend=false
  [ "${2:-}" = "--frontend" ] && frontend=true
  validate_slot "$slot"
  ensure_registry

  slot_taken "$slot" || die "Slot $slot is not in use. Create it first."

  if $frontend; then
    local gfo_wt=$(jq -r ".slots[\"$slot\"].gfo_worktree // empty" "$REGISTRY")
    local vp=$(jq -r ".slots[\"$slot\"].vite_port" "$REGISTRY")
    [ -z "$gfo_wt" ] || [ ! -d "$gfo_wt" ] && die "No frontend worktree for slot $slot"
    echo "Starting Vite on port $vp (slot $slot)..."
    cd "$gfo_wt" && exec npx vite
  else
    local rails_wt=$(jq -r ".slots[\"$slot\"].rails_worktree" "$REGISTRY")
    local rp=$(jq -r ".slots[\"$slot\"].rails_port" "$REGISTRY")
    [ ! -d "$rails_wt" ] && die "Rails worktree not found at $rails_wt"
    echo "Starting Rails on port $rp (slot $slot)..."
    cd "$rails_wt" && exec bundle exec puma -C config/puma.rb -p "$rp"
  fi
}

cmd_stop() {
  local slot="${1:?Usage: worktree-slot stop <slot>}"
  validate_slot "$slot"
  ensure_registry

  slot_taken "$slot" || die "Slot $slot is not in use"

  local rp=$(jq -r ".slots[\"$slot\"].rails_port" "$REGISTRY")
  local vp=$(jq -r ".slots[\"$slot\"].vite_port" "$REGISTRY")

  echo "Stopping slot $slot processes..."
  lsof -ti :"$rp" | xargs kill 2>/dev/null && echo "  Stopped Rails on :$rp" || echo "  No process on :$rp"
  lsof -ti :"$vp" | xargs kill 2>/dev/null && echo "  Stopped Vite on :$vp" || echo "  No process on :$vp"
}

cmd_list() {
  ensure_registry

  local slots=$(jq -r '.slots | keys[]' "$REGISTRY" 2>/dev/null)
  if [ -z "$slots" ]; then
    echo "No active slots."
    echo "Create one with: worktree-slot create <1-5> <branch>"
    return
  fi

  printf "%-5s %-8s %-8s %-25s %-10s\n" "SLOT" "RAILS" "VITE" "BRANCH" "STATUS"
  printf "%-5s %-8s %-8s %-25s %-10s\n" "----" "-----" "----" "------" "------"

  for slot in $slots; do
    local rp=$(jq -r ".slots[\"$slot\"].rails_port" "$REGISTRY")
    local vp=$(jq -r ".slots[\"$slot\"].vite_port" "$REGISTRY")
    local branch=$(jq -r ".slots[\"$slot\"].branch" "$REGISTRY")
    local status=""
    is_port_alive "$rp" && status="rails"
    is_port_alive "$vp" && status="${status:+$status+}vite"
    [ -z "$status" ] && status="stopped"
    printf "%-5s %-8s %-8s %-25s %-10s\n" "$slot" ":$rp" ":$vp" "$branch" "$status"
  done
}

cmd_info() {
  local slot="${1:?Usage: worktree-slot info <slot>}"
  validate_slot "$slot"
  ensure_registry

  slot_taken "$slot" || die "Slot $slot is not in use"

  echo "Slot $slot Details:"
  jq ".slots[\"$slot\"]" "$REGISTRY"

  local rp=$(jq -r ".slots[\"$slot\"].rails_port" "$REGISTRY")
  local vp=$(jq -r ".slots[\"$slot\"].vite_port" "$REGISTRY")
  echo ""
  echo "Port Status:"
  is_port_alive "$rp" && echo "  Rails (:$rp): RUNNING" || echo "  Rails (:$rp): stopped"
  is_port_alive "$vp" && echo "  Vite  (:$vp): RUNNING" || echo "  Vite  (:$vp): stopped"
}

cmd_help() {
  cat <<EOF
Usage: worktree-slot <command> [args]

Commands:
  create <slot> <branch>    Create worktree pair with port assignment
  remove <slot>             Stop processes and remove worktrees
  start  <slot> [--frontend] Start Rails (or Vite with --frontend)
  stop   <slot>             Kill processes on slot's ports
  list                      Show all slots with status
  info   <slot>             Detailed info for one slot

Slot ports (slot N):
  Rails: 3000 + N*10    (e.g., slot 1 = 3010)
  Vite:  3001 + N*10    (e.g., slot 1 = 3011)

Examples:
  worktree-slot create 1 issues/23300
  worktree-slot start 1
  worktree-slot start 1 --frontend
  worktree-slot stop 1
  worktree-slot remove 1
EOF
}

# --- Main ---

require_jq

case "${1:-help}" in
  create)  shift; cmd_create "$@" ;;
  remove)  shift; cmd_remove "$@" ;;
  start)   shift; cmd_start "$@" ;;
  stop)    shift; cmd_stop "$@" ;;
  list)    cmd_list ;;
  info)    shift; cmd_info "$@" ;;
  help|-h|--help) cmd_help ;;
  *) die "Unknown command: $1. Run 'worktree-slot help' for usage." ;;
esac
