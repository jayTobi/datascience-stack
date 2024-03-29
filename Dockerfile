FROM python:3.10.13-bullseye
ENV MLFLOW_HOME /opt/mlflow
ENV MLFLOW_VERSION 2.8.0
ENV SERVER_PORT 5000
ENV SERVER_HOST 0.0.0.0
ENV ARTIFACT_STORE ${MLFLOW_HOME}/artifactStore

RUN mkdir -p ${ARTIFACT_STORE}
RUN chmod -R 777 /opt/mlflow/
RUN pip install psycopg2-binary==2.9.9
RUN pip install mlflow==${MLFLOW_VERSION}    
EXPOSE ${SERVER_PORT}/tcp
WORKDIR ${MLFLOW_HOME}
CMD mlflow server --backend-store-uri postgresql://mlflow-postgres:mlflow-postgres@mlflowdatabase:5432/mlflow --artifacts-destination file:///opt/mlflow/artifactStore/ --host 0.0.0.0
