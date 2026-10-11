# Elasticsearch for RAGFlow on Railway.
# Same version RAGFlow pins (STACK_VERSION=8.11.3). Starts as root only to fix
# ownership of the Railway volume, then drops to the elasticsearch user (uid 1000).
FROM elasticsearch:8.11.3

USER root
COPY --chmod=755 railway-start.sh /usr/local/bin/railway-start.sh

ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/railway-start.sh"]
CMD ["eswrapper"]
