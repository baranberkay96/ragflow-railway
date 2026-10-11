# RAGFlow v0.27 Document AI Engine — Railway template spec

## Listing

- **Name:** RAGFlow v0.27 Document AI Engine (LISTINGS.md name with the pinned version inserted; RAGFlow is pre-1.0, so the label is major.minor with the project's `v` prefix)
- **Description (73 chars):** Chat with PDFs, contracts and docs. Deep-document RAG with Elasticsearch. (unchanged)
- **Category:** AI/ML
- **Tags:** ragflow, rag, document-ai, pdf, elasticsearch, llm, knowledge-base

## Base market template

- **Chosen base: `ragflow-rag-engine` "RAGFlow | Open Source RAG Engine"** (8 active / 18 projects, the most used): RAGFlow + Elasticsearch + MySQL + Redis + object storage, matching upstream's default `DOC_ENGINE=elasticsearch`. Kept: topology, ES security with a generated `elastic` password, `ES_JAVA_OPTS` heap cap, MySQL 9 base settings, `REGISTER_ENABLED` guidance.
- Fixed from that base: Elasticsearch had **no volume** (index lost on every redeploy), `quay.io/minio/minio:latest`, RAGFlow `v0.25.2`, no healthchecks, all parsing inside the web container.
- `ragflow-cpu` (1 active): builds from `orenaksakal/railway-templates` (MIT). Good ideas confirmed independently: volume-ownership fix for ES, `node.store.allow_mmap=false`. Its own MinIO-compatible storage service was not used (no MinIO allowed).
- `ragflow-with-infinity-working` (0 active): Infinity doc engine + `minio/minio` (unpinned), builds from `XavTo/Ragflow` (no license). Not used; Infinity is not the upstream default in v0.27.
- `_upstream/orenaksakal__railway-templates` (MIT): read; the Elasticsearch start approach (fix ownership as root, drop to uid 1000) is the same technique, re-written here. `_upstream/XavTo__Ragflow` (no license): read only, nothing copied.

**Doc engine decision:** `docker/.env` at v0.27.2 still sets `DOC_ENGINE=${DOC_ENGINE:-elasticsearch}`; Infinity, OpenSearch, OceanBase and others are opt-in profiles. The template follows the upstream default (Elasticsearch 8.11.3, the exact `STACK_VERSION` RAGFlow pins), which is also what the listing promises.

**Object storage decision:** RAGFlow's S3 backend (`STORAGE_IMPL=AWS_S3`, `rag/utils/s3_conn.py`) takes `endpoint_url`, `region`, `addressing_style` and a single `bucket` + `prefix_path`, so it works with a Railway Bucket (virtual-hosted style). The MinIO backend would not (the MinIO client uses path-style for non-AWS hosts). No SeaweedFS needed.

## Pinned versions

| Service | Image / source | Tag | Release date | Checked |
|---|---|---|---|---|
| ragflow, ragflow-worker | Dockerfile `services/ragflow` (`FROM infiniflow/ragflow:v0.27.2`) | `v0.27.2` | 2026-09-10 | 2026-10-10 |
| Elasticsearch | Dockerfile `services/elasticsearch` (`FROM elasticsearch:8.11.3`) | `8.11.3` (upstream `STACK_VERSION`) | 2023-12 | 2026-10-10 |
| MySQL | `mysql` | `9` | Railway base | 2026-10-10 |
| Redis | `redis` | `8.2` | Railway base | 2026-10-10 |
| Bucket | Railway Bucket | n/a | n/a | 2026-10-10 |

GitHub currently marks `v1.0.0-rc1` (2026-09-29) as the latest release, but it is a release candidate; `v0.27.2` is the newest stable tag. Upstream compose pins `mysql:8.0.40`; the template uses the Railway base MySQL 9 (the most-used market template already runs RAGFlow on MySQL 9.4).

## Architecture

```
                    HTTPS (public domain)
                            |
     [ragflow :80]  nginx -> UI, /api -> API :9380, /api/v1/admin -> admin :9381, data-source sync
        |     |      |        |
        |     |      |        +---- S3 (uploads, parsed images) ----> [Bucket] (t3.storageapi.dev)
        |     |      +-- Redis task queue --+                              ^
        v     v                             v                              |
   [MySQL] [Elasticsearch :9200] <----- [ragflow-worker: task executors] --+
```

- `ragflow` serves the web UI and API, runs the admin server and data-source synchronization, and enqueues parsing tasks in Redis.
- `ragflow-worker` runs the task executors (DeepDoc OCR/layout parsing, chunking, embedding calls, RAPTOR/GraphRAG jobs) and writes chunks and vectors to Elasticsearch.
- MySQL holds users, tenants, datasets, documents and settings; Elasticsearch holds chunks, full-text and vector indexes; the bucket holds the original files.
- Both RAGFlow services are built from the same Dockerfile; `RAGFLOW_ROLE` chooses the process group via upstream `entrypoint.sh` flags (`--disable-taskexecutor` / `--disable-webserver --workers=N`).

## Services

### ragflow

Built from `services/ragflow` (official image + S3-enabled `service_conf.yaml.template` + `railway-start.sh`). `RAGFLOW_ROLE=web`: nginx/UI, API server, admin server, data-source sync, model-provider migrations.

- Source: repo `baranberkay96/ragflow-railway`, root directory `/services/ragflow` (Dockerfile build)
- Start command: image default
- Pre-deploy command: none
- Healthcheck: `/api/v1/system/healthz` (timeout 900 s)
- Public domain: yes, target port `80`
- TCP proxy: none
- Volume: none
- Restart policy: ON_FAILURE (max 10 retries); replicas: 1; cron: none

| Variable | Value | Description |
|---|---|---|
| `RAGFLOW_ROLE` | `web` | Runs nginx/UI, API server, admin server and data-source sync (no parsing workers). |
| `PORT` | `80` | nginx port serving the UI and proxying the API (public domain target). |
| `DOC_ENGINE` | `elasticsearch` | Document/vector engine (upstream default). |
| `DEVICE` | `cpu` | CPU image; Railway has no GPUs. |
| `API_PROXY_SCHEME` | `python` | Use the Python API server behind the bundled nginx (upstream default). |
| `TZ` | `UTC` | Container timezone (upstream .env uses Asia/Shanghai). |
| `HF_ENDPOINT` | `https://huggingface.co` | Model download endpoint. The image defaults to a China mirror (hf-mirror.com). |
| `ES_HOST` | `${{Elasticsearch.RAILWAY_PRIVATE_DOMAIN}}` | Elasticsearch host (private network, port 9200). |
| `ES_USER` | `elastic` | Elasticsearch user. |
| `ELASTIC_PASSWORD` | `${{Elasticsearch.ELASTIC_PASSWORD}}` | Elasticsearch password (reference). |
| `MYSQL_HOST` | `${{MySQL.MYSQLHOST}}` | MySQL host (private network). |
| `MYSQL_PORT` | `${{MySQL.MYSQLPORT}}` | MySQL port. |
| `MYSQL_USER` | `${{MySQL.MYSQLUSER}}` | MySQL user (root, as upstream). |
| `MYSQL_PASSWORD` | `${{MySQL.MYSQL_ROOT_PASSWORD}}` | MySQL password (reference). |
| `MYSQL_DBNAME` | `${{MySQL.MYSQL_DATABASE}}` | Database for RAGFlow metadata (created by the MySQL image). |
| `REDIS_HOST` | `${{Redis.REDISHOST}}` | Redis host (task queue, locks, caches). |
| `REDIS_PORT` | `${{Redis.REDISPORT}}` | Redis port. |
| `REDIS_PASSWORD` | `${{Redis.REDIS_PASSWORD}}` | Redis password. |
| `STORAGE_IMPL` | `AWS_S3` | Store uploaded files and parsed images in S3 (Railway Bucket) instead of MinIO. |
| `S3_ENDPOINT_URL` | `${{Bucket.ENDPOINT}}` | Railway Bucket S3 endpoint. |
| `S3_REGION` | `${{Bucket.REGION}}` | Railway Bucket region. |
| `S3_BUCKET` | `${{Bucket.BUCKET}}` | Railway Bucket name (single-bucket mode). |
| `S3_ACCESS_KEY` | `${{Bucket.ACCESS_KEY_ID}}` | Bucket access key. |
| `S3_SECRET_KEY` | `${{Bucket.SECRET_ACCESS_KEY}}` | Bucket secret key. |
| `S3_PREFIX_PATH` | `ragflow` | Key prefix; files are stored as <prefix>/<dataset-id>/<file> so per-dataset deletes stay scoped. |
| `S3_ADDRESSING_STYLE` | `virtual` | Railway Buckets require virtual-hosted-style requests. |
| `RAGFLOW_SECRET_KEY` | `${{secret(64, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")}}` | Signs sessions and tokens. Generated once; shared with ragflow-worker. |
| `REGISTER_ENABLED` | `1` | Allow sign-up so you can create the first account. Set to 0 after your team has registered. |
| `ADMIN_DEFAULT_PASSWORD` | `${{secret(24, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")}}` | Password of the built-in superuser admin@ragflow.io (admin server). Generated instead of upstream's 'admin'. |

### ragflow-worker

Same build with `RAGFLOW_ROLE=worker`: only task executors (no HTTP listener). Stateless; scale with replicas or `RAGFLOW_TASK_EXECUTORS`.

- Source: repo `baranberkay96/ragflow-railway`, root directory `/services/ragflow` (Dockerfile build)
- Start command: image default
- Pre-deploy command: none
- Healthcheck: none (no HTTP listener / not applicable)
- Public domain: no
- TCP proxy: none
- Volume: none
- Restart policy: ON_FAILURE (max 10 retries); replicas: 1; cron: none

| Variable | Value | Description |
|---|---|---|
| `RAGFLOW_ROLE` | `worker` | Runs only document-parsing task executors. |
| `RAGFLOW_TASK_EXECUTORS` | `1` | Task executor processes in this container (~1.5-3 GB RAM each while parsing). Scale with this or with replicas. |
| `DOC_ENGINE` | `elasticsearch` | Document/vector engine (upstream default). |
| `DEVICE` | `cpu` | CPU image; Railway has no GPUs. |
| `API_PROXY_SCHEME` | `python` | Use the Python API server behind the bundled nginx (upstream default). |
| `TZ` | `UTC` | Container timezone (upstream .env uses Asia/Shanghai). |
| `HF_ENDPOINT` | `https://huggingface.co` | Model download endpoint. The image defaults to a China mirror (hf-mirror.com). |
| `ES_HOST` | `${{Elasticsearch.RAILWAY_PRIVATE_DOMAIN}}` | Elasticsearch host (private network, port 9200). |
| `ES_USER` | `elastic` | Elasticsearch user. |
| `ELASTIC_PASSWORD` | `${{Elasticsearch.ELASTIC_PASSWORD}}` | Elasticsearch password (reference). |
| `MYSQL_HOST` | `${{MySQL.MYSQLHOST}}` | MySQL host (private network). |
| `MYSQL_PORT` | `${{MySQL.MYSQLPORT}}` | MySQL port. |
| `MYSQL_USER` | `${{MySQL.MYSQLUSER}}` | MySQL user (root, as upstream). |
| `MYSQL_PASSWORD` | `${{MySQL.MYSQL_ROOT_PASSWORD}}` | MySQL password (reference). |
| `MYSQL_DBNAME` | `${{MySQL.MYSQL_DATABASE}}` | Database for RAGFlow metadata (created by the MySQL image). |
| `REDIS_HOST` | `${{Redis.REDISHOST}}` | Redis host (task queue, locks, caches). |
| `REDIS_PORT` | `${{Redis.REDISPORT}}` | Redis port. |
| `REDIS_PASSWORD` | `${{Redis.REDIS_PASSWORD}}` | Redis password. |
| `STORAGE_IMPL` | `AWS_S3` | Store uploaded files and parsed images in S3 (Railway Bucket) instead of MinIO. |
| `S3_ENDPOINT_URL` | `${{Bucket.ENDPOINT}}` | Railway Bucket S3 endpoint. |
| `S3_REGION` | `${{Bucket.REGION}}` | Railway Bucket region. |
| `S3_BUCKET` | `${{Bucket.BUCKET}}` | Railway Bucket name (single-bucket mode). |
| `S3_ACCESS_KEY` | `${{Bucket.ACCESS_KEY_ID}}` | Bucket access key. |
| `S3_SECRET_KEY` | `${{Bucket.SECRET_ACCESS_KEY}}` | Bucket secret key. |
| `S3_PREFIX_PATH` | `ragflow` | Key prefix; files are stored as <prefix>/<dataset-id>/<file> so per-dataset deletes stay scoped. |
| `S3_ADDRESSING_STYLE` | `virtual` | Railway Buckets require virtual-hosted-style requests. |
| `RAGFLOW_SECRET_KEY` | `${{ragflow.RAGFLOW_SECRET_KEY}}` | Must match the ragflow service. |

### Elasticsearch

Built from `services/elasticsearch` (official 8.11.3 image + start script that fixes volume ownership and drops to uid 1000). No HTTP healthcheck: the HTTP API requires the elastic password. Settings with dots are passed as environment variables, as the official image supports.

- Source: repo `baranberkay96/ragflow-railway`, root directory `/services/elasticsearch` (Dockerfile build)
- Start command: image default
- Pre-deploy command: none
- Healthcheck: none (no HTTP listener / not applicable)
- Public domain: no
- TCP proxy: none
- Volume: `/usr/share/elasticsearch/data`
- Restart policy: ON_FAILURE (max 10 retries); replicas: 1; cron: none

| Variable | Value | Description |
|---|---|---|
| `discovery.type` | `single-node` | Single-node cluster (also skips production bootstrap checks). |
| `xpack.security.enabled` | `true` | Require the elastic user's password (as upstream). |
| `xpack.security.http.ssl.enabled` | `false` | Plain HTTP inside the private network (as upstream). |
| `xpack.security.transport.ssl.enabled` | `false` | No transport TLS for a single node (as upstream). |
| `ELASTIC_PASSWORD` | `${{secret(32, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")}}` | Password of the elastic user, generated. |
| `ES_JAVA_OPTS` | `-Xms2g -Xmx2g` | JVM heap. Keep about half of the RAM you want ES to use; without it ES sizes the heap from the host. |
| `network.host` | `::` | Listen on IPv6 and IPv4 so private-network clients can connect in any Railway environment. |
| `node.store.allow_mmap` | `false` | Do not depend on the host's vm.max_map_count, which containers cannot change. |
| `bootstrap.memory_lock` | `false` | memlock ulimits cannot be raised on Railway. |
| `ingest.geoip.downloader.enabled` | `false` | Skip GeoIP database downloads (unused by RAGFlow). |
| `RAILWAY_DEPLOYMENT_DRAINING_SECONDS` | `60` | Allow a clean shutdown on redeploy. |

### MySQL

Railway base MySQL (`_railway-base/mysql.json`) with the start command extended by upstream's `--max-connections=1000` and utf8mb4/unicode collation.

- Source: image `mysql:9`
- Start command: `docker-entrypoint.sh mysqld --innodb-use-native-aio=0 --disable-log-bin --performance_schema=0 --innodb-buffer-pool-size=1G --max-connections=1000 --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci`
- Pre-deploy command: none
- Healthcheck: none (no HTTP listener / not applicable)
- Public domain: no
- TCP proxy: none
- Volume: `/var/lib/mysql`
- Restart policy: ON_FAILURE (max 10 retries); replicas: 1; cron: none

| Variable | Value | Description |
|---|---|---|
| `MYSQLHOST` | `${{RAILWAY_PRIVATE_DOMAIN}}` | Railway Private Domain Name. |
| `MYSQLPORT` | `3306` | MySQL port. |
| `MYSQLUSER` | `root` | MySQL user, used for the Data panel. |
| `MYSQL_URL` | `mysql://${{ MYSQLUSER }}:${{ MYSQL_ROOT_PASSWORD }}@${{ RAILWAY_PRIVATE_DOMAIN }}:3306/${{ MYSQL_DATABASE }}` | URL to connect to MySQL. |
| `MYSQLDATABASE` | `${{ MYSQL_DATABASE }}` | Default database, used for Data panel. |
| `MYSQLPASSWORD` | `${{ MYSQL_ROOT_PASSWORD }}` | Root password, used for Data panel. |
| `MYSQL_DATABASE` | `railway` | Database to be created on image startup. |
| `MYSQL_ROOT_PASSWORD` | `${{ secret(32, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ") }}` | Root password for MySQL DB. |

### Redis

Railway base Redis (`_railway-base/redis.json`, verbatim).

- Source: image `redis:8.2`
- Start command: `/bin/sh -c "rm -rf $RAILWAY_VOLUME_MOUNT_PATH/lost+found/ && exec docker-entrypoint.sh redis-server --requirepass $REDIS_PASSWORD --save 60 1 --dir $RAILWAY_VOLUME_MOUNT_PATH"`
- Pre-deploy command: none
- Healthcheck: none (no HTTP listener / not applicable)
- Public domain: no
- TCP proxy: none
- Volume: `/data`
- Restart policy: ON_FAILURE (max 10 retries); replicas: 1; cron: none

| Variable | Value | Description |
|---|---|---|
| `REDISHOST` | `${{RAILWAY_PRIVATE_DOMAIN}}` | Private network hostname of the Redis service, only resolvable from services in the same environment |
| `REDISPORT` | `6379` | Port that Redis listens on |
| `REDISUSER` | `default` | Username for authenticating with Redis |
| `REDIS_URL` | `redis://${{ REDISUSER }}:${{ REDIS_PASSWORD }}@${{ REDISHOST }}:${{ REDISPORT }}` | Connection string for connecting to Redis using the private network |
| `REDISPASSWORD` | `${{REDIS_PASSWORD}}` | Alias of REDIS_PASSWORD for clients that expect the unseparated name |
| `REDIS_PASSWORD` | `${{ secret(32, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ") }}` | Randomly generated password for authenticating with Redis |

### Bucket (Railway Bucket)

- S3-compatible Railway Bucket. Exposes `BUCKET`, `ACCESS_KEY_ID`, `SECRET_ACCESS_KEY`, `REGION`, `ENDPOINT` for references such as `${{Bucket.ENDPOINT}}`.
- Private only, virtual-hosted-style addressing, reached over its public endpoint (`https://t3.storageapi.dev`).

## Improvements over market templates

1. **RAGFlow v0.27.2** (current stable) instead of v0.25.2 / v0.26.4, including the v0.27 model-provider table migrations (`--init-model-provider-tables`, as in upstream compose).
2. **No MinIO:** uploads and parsed images go to a Railway Bucket through RAGFlow's S3 backend (virtual-hosted addressing, single bucket with a `ragflow/` prefix so deleting a dataset only removes its own objects).
3. **Elasticsearch on a volume** with ownership fixed at start (the most-used market template had no ES volume, so every redeploy wiped the index), heap capped, `allow_mmap=false` and `memory_lock=false` for container limits, IPv4+IPv6 listener.
4. **Scalable parsing workers:** document parsing runs in `ragflow-worker` (replicas or `RAGFLOW_TASK_EXECUTORS`), so heavy PDFs no longer compete with the UI/API for memory.
5. **Readiness healthcheck** `/api/v1/system/healthz` (checks MySQL, Redis, Elasticsearch and storage) instead of none.
6. **Admin superuser secured:** upstream ships `ADMIN_DEFAULT_PASSWORD=admin` and nginx exposes `/api/v1/admin`; the template generates the password.
7. **Generated secrets** for MySQL, Redis, Elasticsearch and `RAGFLOW_SECRET_KEY` (otherwise RAGFlow auto-generates and stores one in Redis with a security warning).
8. **Model downloads from huggingface.co** (`HF_ENDPOINT`), not the China mirror baked into the image; timezone UTC.
9. MySQL tuned like upstream (`max_connections=1000`, utf8mb4/unicode collation) on top of the Railway base definition.

## Resource estimate

RAGFlow is heavy. Upstream recommends at least 4 CPU cores, 16 GB RAM and 50 GB disk for the full Docker stack.

| Service | Idle RAM | Typical RAM | Typical vCPU | Volume |
|---|---|---|---|---|
| ragflow (UI/API/admin/sync) | 1.2 GB | 2.0 GB | 0.4 | – |
| ragflow-worker (1 executor) | 1.5 GB | 3.0 GB | 1.2 (bursts while parsing) | – |
| Elasticsearch (2 GB heap) | 2.5 GB | 3.0 GB | 0.3 | 5–20 GB |
| MySQL | 0.5 GB | 1.2 GB | 0.1 | 1–2 GB |
| Redis | 0.03 GB | 0.1 GB | 0.02 | < 0.5 GB |
| Bucket | – | – | – | 1–50 GB objects |
| **Total** | **~5.7 GB** | **~9.3 GB** | **~2.0** | **~7–23 GB + bucket** |

Railway prices: RAM $10/GB-month, vCPU $20/vCPU-month, volume $0.15/GB-month, Bucket $0.015/GB-month.

- **Idle:** 5.7 GB × $10 + ~0.3 vCPU × $20 + 7 GB × $0.15 ≈ **$64/month**.
- **Typical (team knowledge base, a few hundred documents parsed per week):** 9.3 GB × $10 + 2.0 vCPU × $20 + 15 GB × $0.15 + 20 GB bucket × $0.015 ≈ **$136/month**. Large ingestion jobs temporarily add ~2–3 GB and 1–2 vCPU per extra executor. LLM/embedding API costs are billed by your model provider.

**Minimum plan: Hobby** (Elasticsearch and the worker each need more than Trial's 1 GB). Pro is recommended for production: more executors, larger ES heap and volumes above Hobby's 5 GB limit.

## Verification checklist

1. All services deploy green; `ragflow` healthcheck `/api/v1/system/healthz` returns 200 with `db`, `redis`, `doc_engine` and `storage` all `ok` (first boot can take several minutes).
2. Open the public URL, register the first account (`REGISTER_ENABLED=1`), then set `REGISTER_ENABLED=0` and redeploy `ragflow`.
3. In Model providers, add an LLM and an embedding model (e.g. OpenAI); create a dataset, upload a PDF and click Parse. `ragflow-worker` logs show the task; status reaches "Success".
4. Confirm the bucket contains objects under `ragflow/<dataset-id>/`.
5. Ask a question in Chat against the dataset; answers cite chunks.
6. Delete a test dataset; its objects disappear from the bucket and no error is logged.
7. Redeploy Elasticsearch, MySQL and both RAGFlow services; datasets and chunks are still searchable.
8. Log in to the admin API/CLI as `admin@ragflow.io` with `ADMIN_DEFAULT_PASSWORD`.
9. Scale `ragflow-worker` to 2 replicas and parse several files in parallel.

## Open questions

- **Dataset deletion on Railway Buckets:** RAGFlow's S3 backend deletes a dataset's objects with `ListObjectVersions` + `DeleteObjects`. Tigris (Railway's provider) supports both, but Railway's bucket docs list only ListObjects v1/v2; if version listing is rejected, dataset deletion fails with a storage error. Test step 6 covers this.
- **MySQL 9 vs upstream 8.0.40:** works in the most-used market template; not verified against RAGFlow's CI. Switch the MySQL image to `mysql:8.0` if migrations fail.
- **Concurrent first start:** both RAGFlow services run `init_database_tables` on boot; a race on the very first deploy can make one restart once (restart policy handles it).
- **Elasticsearch disk watermarks:** ES defaults (85/90/95 %) apply. On a 5 GB Hobby volume indices turn read-only around 4.75 GB used; grow the volume before that.
- **No local embedding service:** upstream's optional TEI container is not included; configure an embedding provider in the UI. A TEI service can be added later.
- Not deploy-tested in this package (local files only).

## Deploy test findings (2026-10-11)

Elasticsearch crash-looped on the first Railway test, so RAGFlow could not connect. Two bugs, both fixed and verified locally (cluster green, `elastic` login 200, wrong password 401):
- `network.host=::` — the image writes `dotted.env` settings to YAML unquoted and `::` breaks the parse ("mapping values are not allowed here"). Now `0.0.0.0` (Java binds dual-stack).
- The wrapper dropped privileges with `chroot`, which resets the working directory to `/`. Upstream's entrypoint only stores `ELASTIC_PASSWORD` when `bin/elasticsearch-users` exists relative to the cwd, so the password was silently never set and RAGFlow's authenticated connection would have failed. Now `cd $ES_HOME` + `setpriv`.

