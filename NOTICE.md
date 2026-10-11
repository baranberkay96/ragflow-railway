# Notice

## Upstream software

- **RAGFlow** — Apache-2.0. Copyright (c) The InfiniFlow Authors. Image used: `infiniflow/ragflow:v0.27.2` (published by InfiniFlow on Docker Hub), extended in `services/ragflow/Dockerfile`.
- **Elasticsearch** — image `elasticsearch:8.11.3` (Docker official image, published by Elastic). Elasticsearch 8.11 is distributed under the Elastic License 2.0 / SSPL (the default distribution); running it unmodified as a backing service is permitted under ELv2. Extended only with a start script.
- **MySQL** — GPL-2.0 (Community Edition). Image `mysql:9` (Docker official image, Railway base definition).
- **Redis** — Redis 8 is available under RSALv2/SSPLv1/AGPLv3. Image `redis:8.2` (Docker official image).

## Verified against

| What | Source | Version / ref | Checked |
|---|---|---|---|
| Services, profiles, default doc engine, ES settings | https://github.com/infiniflow/ragflow/blob/v0.27.2/docker/docker-compose-base.yml, `docker/docker-compose.yml`, `docker/.env` | v0.27.2 | 2026-10-10 |
| Config template and rendering | `docker/service_conf.yaml.template`, `docker/entrypoint.sh` | v0.27.2 | 2026-10-10 |
| nginx routes (UI, `/api`, `/api/v1/admin`) | `docker/nginx/ragflow.conf.python` | v0.27.2 | 2026-10-10 |
| S3 storage backend (addressing style, single bucket, prefix, deletes) | `rag/utils/s3_conn.py`, `common/settings.py` | v0.27.2 | 2026-10-10 |
| Admin bootstrap password handling | `admin/server/auth.py` | v0.27.2 | 2026-10-10 |
| Health endpoint | `api/apps/restful_apis/system_api.py`, `api/utils/health_utils.py` | v0.27.2 | 2026-10-10 |
| Model-provider migrations | `tools/scripts/run_migrations.sh` | v0.27.2 | 2026-10-10 |
| Image ENTRYPOINT, `HF_ENDPOINT` default | `Dockerfile` | v0.27.2 | 2026-10-10 |
| Release status (`v1.0.0-rc1` is an RC; `v0.27.2` latest stable) | https://github.com/infiniflow/ragflow/releases | — | 2026-10-10 |
| Railway Bucket behaviour | https://docs.railway.com/storage-buckets | docs | 2026-10-10 |

## Adapted code

- `services/ragflow/service_conf.yaml.template` is adapted from `docker/service_conf.yaml.template` of infiniflow/ragflow v0.27.2, Copyright The InfiniFlow Authors, licensed under the Apache License 2.0 (https://www.apache.org/licenses/LICENSE-2.0). Changes: added an `s3` section driven by environment variables for the Railway Bucket, removed the TEI default-embedding block and unused doc-engine sections, made the Redis port configurable and removed default passwords. The header of the file states that it was modified.
- `services/ragflow/railway-start.sh`, `services/elasticsearch/Dockerfile` and `services/elasticsearch/railway-start.sh` were written for this template. The Elasticsearch ownership fix uses the same general technique as `templates/ragflow/elasticsearch-start.sh` in orenaksakal/railway-templates (MIT, Copyright (c) 2026 orenaksakal); no lines were copied.
- MySQL and Redis definitions come from this repository's `_railway-base` files.

## Reference only (not copied)

- `_upstream/XavTo__Ragflow` (no license): read only.
- `_upstream/orenaksakal__railway-templates` (MIT): read for ideas; see above.
- Railway marketplace templates `ragflow-rag-engine`, `ragflow-cpu`, `ragflow-with-infinity-working`: configuration read for ideas; no text copied.

## Trademarks

RAGFlow and InfiniFlow are trademarks of their owner; Elasticsearch is a trademark of Elasticsearch B.V.; MySQL is a trademark of Oracle; Redis is a trademark of Redis Ltd. This is a community template and is not affiliated with or endorsed by InfiniFlow or Elastic.
