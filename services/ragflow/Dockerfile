# RAGFlow (CPU image) for Railway.
# Official image + an S3-enabled service_conf template (Railway Bucket) + a small
# launcher that selects the process group per Railway service via RAGFLOW_ROLE.
FROM infiniflow/ragflow:v0.27.2

COPY service_conf.yaml.template /ragflow/conf/service_conf.yaml.template
COPY --chmod=755 railway-start.sh /ragflow/railway-start.sh

WORKDIR /ragflow
ENTRYPOINT ["/ragflow/railway-start.sh"]
