#!/bin/bash
# Railway volumes are mounted root-owned; Elasticsearch refuses to run as root.
# Fix ownership, make /tmp usable for the image's entrypoint, then exec the
# upstream entrypoint as uid 1000 (gid 0, as in the official image).
set -euo pipefail

DATA_DIR=/usr/share/elasticsearch/data
mkdir -p "$DATA_DIR"
rm -rf "$DATA_DIR/lost+found"
chown -R 1000:0 "$DATA_DIR"
chmod 1777 /tmp

exec chroot --userspec=1000:0 / env HOME=/usr/share/elasticsearch \
  /usr/local/bin/docker-entrypoint.sh "$@"
