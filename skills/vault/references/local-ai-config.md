# Local AI Configuration

## Endpoints

All services run on Proxmox GPU server at `192.168.1.150`:

| Service | Port | URL |
|---------|------|-----|
| **Chat/Completion** | 8080 | `http://192.168.1.150:8080/v1` |
| **Embeddings** | 8082 | `http://192.168.1.150:8082/v1` |
| **Re-ranking** | 8083 | `http://192.168.1.150:8083/v1` |

## Environment Variables

Set in `~/.zshrc`:

```bash
# Chat/Completion
export VAULT_AI_API_URL="http://192.168.1.150:8080/v1"
export VAULT_AI_MODEL=""                                  # auto-detect from /v1/models

# Embeddings (separate server)
export VAULT_AI_EMBED_URL="http://192.168.1.150:8082/v1"
export VAULT_AI_EMBED_MODEL=""                            # auto-detect from /v1/models

# Re-ranking (separate server)
export VAULT_AI_RERANK_URL="http://192.168.1.150:8083/v1"
export VAULT_AI_RERANK_MODEL=""                           # auto-detect from /v1/models
```

## SSH Tunnel Fallback

If LAN is unreachable, tunnel all three ports:
```bash
ssh -N -L 8080:localhost:8080 -L 8082:localhost:8082 -L 8083:localhost:8083 user@192.168.1.150
```
Then use `localhost` instead of `192.168.1.150`.

## Resolving Endpoints

```bash
CHAT_URL="${VAULT_AI_API_URL:-http://192.168.1.150:8080/v1}"
EMBED_URL="${VAULT_AI_EMBED_URL:-http://192.168.1.150:8082/v1}"
RERANK_URL="${VAULT_AI_RERANK_URL:-http://192.168.1.150:8083/v1}"
```

## Availability Check

```bash
CHAT_OK=$(curl -s -o /dev/null -w "%{http_code}" "$CHAT_URL/models" 2>/dev/null)
EMBED_OK=$(curl -s -o /dev/null -w "%{http_code}" "$EMBED_URL/models" 2>/dev/null)
RERANK_OK=$(curl -s -o /dev/null -w "%{http_code}" "$RERANK_URL/models" 2>/dev/null)
```

**Fallback:** If endpoint returns non-200, try `localhost` (SSH tunnel). If still fails, use Claude (current session) for chat tasks. Embedding/reranking tasks that fail silently degrade to keyword search via ripgrep.

## Auto-Detect Models

```bash
curl -s "$CHAT_URL/models" | jq -r '.data[].id'
curl -s "$EMBED_URL/models" | jq -r '.data[].id'
curl -s "$RERANK_URL/models" | jq -r '.data[].id'
```

## API Usage

### Chat Completion
```bash
curl -s "$CHAT_URL/chat/completions" \
  -H "Content-Type: application/json" \
  -d "{\"model\": \"$VAULT_AI_MODEL\", \"messages\": [{\"role\": \"user\", \"content\": \"text\"}]}"
```

### Embeddings
```bash
curl -s "$EMBED_URL/embeddings" \
  -H "Content-Type: application/json" \
  -d "{\"model\": \"$VAULT_AI_EMBED_MODEL\", \"input\": \"text to embed\"}"
```

### Re-ranking
```bash
curl -s "$RERANK_URL/rerank" \
  -H "Content-Type: application/json" \
  -d "{\"model\": \"$VAULT_AI_RERANK_MODEL\", \"query\": \"search query\", \"documents\": [\"doc1\", \"doc2\"]}"
```

## Task-to-Endpoint Mapping

| Task | Endpoint | Fallback |
|------|----------|----------|
| Tagging/Categorization | Chat (:8080) | Claude |
| Summarization | Chat (:8080) | Claude |
| Chat with vault | Chat (:8080) | Claude |
| Semantic search | Embed (:8082) | ripgrep keyword search |
| Duplicate detection | Embed (:8082) | title/content comparison |
| Search result ranking | Rerank (:8083) | match-count sorting |
