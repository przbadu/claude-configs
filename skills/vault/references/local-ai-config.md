# Local AI Configuration

## Supported Backends

The vault-ai skill supports any OpenAI-compatible API running locally:

### Ollama (default)
```bash
# Check if running
curl -s http://localhost:11434/api/tags

# Embedding
curl -s http://localhost:11434/api/embeddings -d '{"model": "qwen2.5-embed", "prompt": "text"}'

# Chat completion
curl -s http://localhost:11434/api/chat -d '{"model": "qwen2.5", "messages": [{"role": "user", "content": "text"}]}'
```

### vLLM / OpenAI-compatible server
```bash
# Check if running
curl -s http://localhost:8000/v1/models

# Embedding
curl -s http://localhost:8000/v1/embeddings -H "Content-Type: application/json" -d '{"model": "qwen2.5-embed", "input": "text"}'

# Chat completion
curl -s http://localhost:8000/v1/chat/completions -H "Content-Type: application/json" -d '{"model": "qwen2.5", "messages": [{"role": "user", "content": "text"}]}'
```

## Model Recommendations

| Task | Model | Why |
|------|-------|-----|
| Embedding | `qwen2.5-embed` or `bge-m3` | Fast, good quality |
| Re-ranking | `bge-reranker-v2-m3` | Accurate relevance scoring |
| Tagging/Categorization | `qwen2.5:7b` | Good enough, fast |
| Summarization | `qwen2.5:14b+` or Claude | Better quality for longer text |

## Availability Check

Before using local AI, always check availability:
```bash
# Try Ollama first
OLLAMA="000"
# Then try vLLM/OpenAI-compatible
VLLM="000"
```

If neither responds with 200, fall back to using Claude in the current session.

## Configuration

Users can override defaults by setting environment variables:
- `VAULT_AI_API_URL` — Base URL for OpenAI-compatible API (default: http://localhost:11434)
- `VAULT_AI_MODEL` — Model name for chat (default: qwen2.5)
- `VAULT_AI_EMBED_MODEL` — Model name for embeddings (default: qwen2.5-embed)
