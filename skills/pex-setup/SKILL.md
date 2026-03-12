---
name: pex:setup
description: >
  ProcurementExpress CLI setup, authentication, company selection, and configuration.
  Use when authenticating to the ProcurementExpress API (V1 token or V3 OAuth2),
  switching companies, managing config profiles (production/staging), or checking auth
  status. Also covers installing the CLI and skills into a project.
  Triggers on: pex setup, pex install, pex auth, login, authenticate, token, switch
  company, config profile, staging, production, pex config, who am i, current user.
---

# ProcurementExpress CLI Setup

## Installation

### CLI

```bash
# From npm (when published)
npm install -g @procurementexpress/cli

# From source
git clone https://github.com/przbadu/procurementexpress-cli.git
cd procurementexpress-cli && npm install && npm run build && npm link
```

### Skills (copy into any project)

```bash
# Copy all pex skills into your project
cp -r /path/to/procurementexpress-cli/.claude/skills/pex-* /path/to/your-project/.claude/skills/
```

Once published to npm, this will be automated:
```bash
npx @procurementexpress/cli install-skills
```

## Authentication

Authentication is required before any API command. Credentials persist in config.

### V1 Token Auth (simple, recommended)

```bash
pex auth login --token=<TOKEN> --company-id=<COMPANY_ID>
```

### V3 OAuth2 Auth (email/password)

```bash
pex auth login --email=user@co.com --password=secret \
  --client-id=<ID> --client-secret=<SECRET> --api-version=v3
```

### Verify Auth

```bash
pex auth status    # Shows profile, base URL, token validity, company
pex auth whoami    # Current user from API (id, email, name, companies)
```

### Logout

```bash
pex auth logout    # Revoke token + clear from config
```

## Company Selection

After authenticating, set the active company:

```bash
# List available companies
pex company list

# Set active company (persisted in profile)
pex company set <COMPANY_ID>

# Verify
pex company details
```

## Config Profiles (Staging/Production)

```bash
# Add staging profile
pex config add-profile staging --base-url=https://staging.procurementexpress.com

# Switch to staging and authenticate
pex config use staging
pex auth login --token=STAGING_TOKEN --company-id=STAGING_ID

# Switch back
pex config use production

# View config (tokens redacted)
pex config show

# Set default output format
pex config set defaultFormat table
```

## Priority Order (highest wins)

1. CLI flags: `--token`, `--base-url`, `--company-id`, `--api-version`
2. Environment variables: `PROCUREMENTEXPRESS_AUTH_TOKEN`, `PROCUREMENTEXPRESS_API_BASE_URL`, `PROCUREMENTEXPRESS_COMPANY_ID`, `PROCUREMENTEXPRESS_API_VERSION`
3. Active profile in config file

## Current User Management

```bash
pex auth whoami    # Get current user profile with company memberships and roles
```

## Typical Setup Workflow

```
1. pex auth login --token=<TOKEN> --company-id=<ID>
2. pex company list                    # see available companies
3. pex company set <COMPANY_ID>        # pick working company
4. pex company details                 # verify settings, custom fields, currencies
5. Start using other pex commands
```
