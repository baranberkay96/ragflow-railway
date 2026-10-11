#!/usr/bin/env bash
# Chooses which RAGFlow processes run in this container. All roles use the
# upstream docker/entrypoint.sh (which renders conf/service_conf.yaml from the
# template and environment variables).
#
#   RAGFLOW_ROLE=web     nginx (UI on :80) + API server + admin server + data-source sync
#   RAGFLOW_ROLE=worker  RAGFLOW_TASK_EXECUTORS document-parsing task executors only
#   RAGFLOW_ROLE=all     everything in one container (upstream default layout)
set -euo pipefail
cd /ragflow

ROLE="${RAGFLOW_ROLE:-web}"
EXECUTORS="${RAGFLOW_TASK_EXECUTORS:-1}"

case "$ROLE" in
  web)
    exec ./entrypoint.sh --disable-taskexecutor --enable-adminserver --init-model-provider-tables
    ;;
  worker)
    exec ./entrypoint.sh --disable-webserver --disable-datasync --workers="${EXECUTORS}"
    ;;
  all)
    exec ./entrypoint.sh --enable-adminserver --init-model-provider-tables --workers="${EXECUTORS}"
    ;;
  *)
    echo "[railway-start] unknown RAGFLOW_ROLE '${ROLE}' (expected web, worker or all)" >&2
    exit 64
    ;;
esac
