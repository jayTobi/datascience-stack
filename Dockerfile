FROM python:3.8-buster
ENV MLFLOW_HOME /opt/mlflow
ENV MLFLOW_VERSION 1.19.0
ENV SERVER_PORT 5000
ENV SERVER_HOST 0.0.0.0
ENV ARTIFACT_STORE ${MLFLOW_HOME}/artifactStore

RUN pip install psycopg2-binary==2.8.6 
RUN pip install mlflow==${MLFLOW_VERSION} && \
    mkdir -p ${ARTIFACT_STORE}
RUN chmod -R a+rwx /opt/mlflow/
EXPOSE ${SERVER_PORT}/tcp
WORKDIR ${MLFLOW_HOME}
CMD mlflow server --backend-store-uri postgresql://mlflow-postgres:mlflow-postgres@mlflowdatabase:5432/mlflow --default-artifact-root file:///opt/mlflow/artifactStore/ --host 0.0.0.0
