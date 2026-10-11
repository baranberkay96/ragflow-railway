# Deploy and Host RAGFlow with Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/ragflow-v027-document-ai-engine)

RAGFlow is an open-source retrieval-augmented generation engine built around deep document understanding: it parses PDFs, scans, tables and slides into well-structured chunks and answers questions with traceable citations. This community template deploys RAGFlow v0.27 on Railway with Elasticsearch, MySQL, Redis, a Railway Bucket and a separate parsing worker.

## About Hosting RAGFlow

RAGFlow combines several components. The web service serves the UI and API through nginx; task executors run the DeepDoc OCR and layout models that turn uploaded files into chunks, call your embedding model and write chunks and vectors to Elasticsearch. MySQL stores users, datasets and settings, Redis carries the task queue, and object storage keeps the original files. Parsing is CPU- and memory-intensive, so this template runs it in its own service that you can scale independently of the UI. Original files go to a Railway Bucket through RAGFlow's S3 backend instead of a MinIO container, and every password and secret is generated at deploy time. Expect a memory-heavy stack: plan for roughly 6–10 GB of RAM.

## Common Use Cases

- Chat with contracts, policies, manuals and research papers, with answers that cite the exact source passages.
- Build an internal knowledge base over scanned PDFs, tables and slide decks that plain text extractors handle poorly.
- Expose a retrieval API or MCP endpoint for AI agents and assistants.
- Create agent workflows that combine document retrieval with web search and tools.

## Dependencies for RAGFlow Hosting

- RAGFlow CPU image `infiniflow/ragflow:v0.27.2` (web and worker roles)
- Elasticsearch 8.11.3 (the version RAGFlow pins)
- MySQL (Railway MySQL 9) and Redis (Railway Redis 8.2)
- S3-compatible object storage (Railway Bucket)
- An LLM and an embedding model provider (OpenAI, Azure, Gemini, Ollama, a LiteLLM gateway, ...), configured in the UI

### Deployment Dependencies

- RAGFlow documentation: https://ragflow.io/docs/dev/
- Docker deployment files: https://github.com/infiniflow/ragflow/tree/v0.27.2/docker
- Configuration reference: https://ragflow.io/docs/dev/configurations
- Release notes: https://github.com/infiniflow/ragflow/releases/tag/v0.27.2
- Railway Buckets: https://docs.railway.com/storage-buckets

### Implementation Details

| Service | Role | Public | Storage |
|---|---|---|---|
| ragflow | nginx + UI, API server, admin server, data-source sync | Yes (port 80) | – |
| ragflow-worker | Document parsing task executors | No | – |
| Elasticsearch | Chunks, full-text and vector index | No | Volume |
| MySQL | Users, datasets, documents, settings | No | Volume |
| Redis | Task queue, locks, caches | No | Volume |
| Bucket | Uploaded files and parsed images | – | Railway Bucket |

**First login**

1. Wait for the `ragflow` healthcheck (`/api/v1/system/healthz`) to pass; the first start initializes the database and can take several minutes.
2. Open the public URL and register your account. Registration is open by default (`REGISTER_ENABLED=1`) so you can create the first users; set it to `0` on the `ragflow` service afterwards.
3. Under Model providers, add your chat and embedding models. Then create a dataset, upload files and start parsing.
4. The built-in superuser `admin@ragflow.io` (admin server and CLI) uses the generated `ADMIN_DEFAULT_PASSWORD` from the `ragflow` variables.

**Scaling:** add replicas to `ragflow-worker`, or raise `RAGFLOW_TASK_EXECUTORS`, to parse more documents in parallel (each executor needs roughly 1.5–3 GB of RAM while parsing). Raise `ES_JAVA_OPTS` on Elasticsearch for large datasets.

**Pinning and upgrades:** the RAGFlow version is the `FROM` line in `services/ragflow/Dockerfile` (shared by both RAGFlow services). Read the release notes before upgrading; database migrations run on start. Elasticsearch is pinned in `services/elasticsearch/Dockerfile`; keep it on the version RAGFlow's `docker/.env` specifies.

### Why Deploy RAGFlow on Railway?

Railway runs the whole stack as one project with private networking, volumes, a managed S3 bucket and generated credentials, so you can stand up a production-shaped RAGFlow without assembling Docker Compose on a VM. Parsing capacity scales with replicas, and you pay for the memory and CPU the stack actually uses.
