# Data Science Stack using MLFlow, DVC and OpenSearch

## Overview

This guide helps you to set up a stack containing useful tools
for data science projects.
It focuses on additional tools to support the process as much as
possible. This includes:

- MLFLow for the ML lifecycle, e.g. tracking metrics
- DVC for managing and versioning data
- OpenSearch for managing logs and providing a UI for analysing logs

To combine everything into an easily executable environment we will
use Docker Compose to manage the different components.

## Prerequisite

To follow this guide you need some additional resources which might not be
available on your system. Please have a look at their documentation to get started.

- Docker <https://docs.docker.com/engine/>
- Docker Compose <https://docs.docker.com/compose/>

For development Visual Studio Code (VS Code) is used: <https://code.visualstudio.com/>

## Docker and Docker Compose

To run the environment inside docker just open a terminal, browse to the folder
containing the `docker-compose.yml` and run the following command:
`docker-compose up -d`
(-d runs the containers in detach mode and is optional)

## OpenSearch

OpenSearch (<https://opensearch.org>) is now used as a replacement of the elastic stack (ELK: elastic search, logstash, kibana) for log aggregation and analysis. 

The `docker-compose.yml` inside this repo includes everything to run the stack.

A more detailed guide for setting up the OpenSearch using docker and/or Docker Compose can be found here <https://opensearch.org/docs/latest/install-and-configure/install-opensearch/docker/>.

After everything started successfully you can access the UI using a web browser and the URL <http://localhost:5601>
using user and password "admin".

### Problems with start up

If the following error is displayed during the start of opensearch 
``` max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]```

You need to increase the value:
1. On Linux 
   1. sysctl -w vm.max_map_count=262144
2. On Windows
   1. wsl -d docker-desktop  
   2. sysctl -w vm.max_map_count=262144

## Python logging

An important aspect of longer running experiments is logging information. This will be helpful for understanding the program flow and finding errors.
Using ELK these information can be accessed easily and in a long term.

We configure Python logging and make the output accessible
for ELK.
Details on the Python config can be found here <https://docs.python.org/3/howto/logging.html#configuring-logging>

If you get a "KeyError: 'formatters'" your configuration can not be found by Python (it is searching in the current working directory (os.getcwd()) - check your path and try again.

## fluentd and OpenSearch on Linux (to be updated)

To send our logging output to OpenSearch we use fluentd <https://docs.fluentd.org/>.

For installing fluentd follow the appropriate guide on <https://docs.fluentd.org/installation>.

### Configuration

The fluentd service will be running on the same machine as the Python code itself - although it would be possible do include this into a separate Docker container as well.

Open the file `/etc/td-agent/td-agent.conf` and replace the content, probably making a backup, with the following content (as seen in the `td-agent.conf` in this repo)

```xml
<source>
  @type forward
  port 24224
</source>

<match ds.**>
  @type opensearch
  host 127.0.0.1
  port 9200
  logstash_format true
  include_timestamp true # defaults to false
  with_transporter_log true
  flush_interval 30s
</match>
```

More detailed documentation can be found here.

- <https://docs.fluentd.org/output/elasticsearch>
- fluentd and Python <https://docs.fluentd.org/language-bindings/python>

Make sure your docker-compose is running and then restart the fluentd service.

For (re-)starting and status of the service use
`sudo systemctl status td-agent.service`.

You can check the output of the fluentd agent by inspecting the following file, e.g. using
`tail -f /var/log/td-agent/td-agent.log`

If the start and connection to OpenSearch is successful you should see something like

```
GET http://127.0.0.1:9200/ [status:200, request:0.002s, query:n/a]
```

Later you can also verify that the LOG messages from your Python code are send to OpenSearch by looking for lines like:

```
POST http://127.0.0.1:9200/_bulk [status:200, request:0.304s, query:0.298s]
```

These are triggered periodically depending on the configured flush_interval above.


## Fluentd and Windows

For instructions how to install fluentd on Windows see <https://docs.fluentd.org/installation/install-by-msi>

## Using fluentd and Python logging

Here we show 2 different versions of the logging configuration.

A more manual approach that can be found inside the file `logging/fluentd_test.py` and the easier and probably more suitable way using **external** configuration (logging.yml) can be found in `logging/fluentd_with_config.py`.

The third code inside `logging/logging_test.py` just configures standard Python logging without fluentd.

You can just run the Python scripts and check the fluentd log and the Kibana Web UI.

## MLFlow

MLFlow will be used as a server and client for managing models, experiments, recipes/pipelines.

### MLFlow Tracking Server

This is the backend server the clients communicate with.
It will include a database (PostgreSQL in docker-compose) and an (local) artifact store
for models and other artifacts.

Multiple clients could connect to the same MLFLow server for tracking experiments, e.g. a team
could work with the same server to share models or simplify tracking.

In addition to PostgreSQL the docker installs `adminer` a PHP UI to connect to the database.

You can open it using <http://localhost:8080> and connect to the database running inside the docker container using the server `mlflowdatabase:5432`, database `mlflow` and user/password (mlflow-postgres/mlflow-postgres) from the `docker-compose.yml` file.

### MLFLow UI

MLFlow provides a UI for browsing experiments and models
that can be accessed using your browser <http://localhost:5000>.

### MLFlow client - using MLFLow

The folder `mlflow` contains examples using MLFlow client APIs to connect and communicate with the MLFLow Tracking Server inside the Docker container. (Make sure you have installed inside your Python environment, e.g. using the requirements.txt in this repo)

For using a remote tracking server you have to configure:

- Set the remote tracking url - using the API or **environment variables if you run multi-step workflows!**
-  Use a drive/storage that is accessible under the same name inside the remote server and the machine your running your experiment
  - Normally this would be some kind of cloud storage (e.g. AWS S3) or a shared network folder
  - For the local docker example there are two ways with direct file system access or better the first option
    - Use remote artifact proxy (this is configured in the current version of the compose and Dockerfile) see
      - <https://mlflow.org/docs/latest/tracking.html#scenario-5-mlflow-tracking-server-enabled-with-proxied-artifact-storage-access>
    - Use a Docker volume (line 30 in docker-compose.yml) and create a symbolic link (this causes permission issues in some cases)
      - Find the location where Docker stores the data inside the Docker volume with
      - `docker volume ls`: list all volumes. Look for the one ending with `mlflow-data` and inspect it using
      - ` docker volume inspect datascience-stack_mlflow-data`: The JSON output of this command contains the required key "Mountpoint". Copy its value and create a symbolic link
      - `sudo ln -s /var/lib/docker/volumes/datascience-stack_mlflow-data/_data/artifactStore/ /opt/mlflow/artifactStore`: Make sure to use the same folder name inside the docker and the host.
        In the Dockerfile we specified it as `/opt/mlflow/artifactStore`
    - Or use a direct mount (line 31 in docker-compose.yml)
      - just ensure the folder exists, you have permissions and that it has the same name, i.e. `/opt/mlflow` (sub-folders will be created automatically)

After mounting the folder you can simply run `mlflow/simple.py` then open up the MLFlow UI and you should find a new experiment `my-simple-experiment` with some metrics. After clicking on a run you can find more details and you **should ensure** that the artifacts were saved correctly by scrolling down the page and click on `test.txt` under the Artifacts section. If it is empty you most probably run into permission errors and couldn't save the file.

### MLFlow basics and concepts

To get a better understanding of the underlying ideas and terminology of MLFLow and how to use it have a look at the following pages:

- <https://www.mlflow.org/docs/latest/quickstart.html>
- <https://www.mlflow.org/docs/latest/concepts.html>

## DVC - Data Version Control (to be updated)

> Data Version Control, or DVC, is a data and ML experiment management tool that takes advantage of the existing engineering toolset that you're already familiar with (Git, CI/CD, etc.).
> -- <cite><https://dvc.org/doc></cite>

Although DVC is much more than a simple data versioning tool this tutorial will use it for exactly that. Other aspects like tracking experiments, metrics and models will be done by MLFlow as described above.

This tutorial will take you through small parts taken from the official tutorials (<https://dvc.org/doc/use-cases/versioning-data-and-model-files/tutorial>).

- Make sure you have DVC installed
  (<https://dvc.org/doc/install>)
- Run `dvc init` (only required on new git repositories, already done in this tutorial)
  - This will add some new files/folders all containing .dvc\* in their names
  - These files contain metadata and will be used by DVC to keep track of the data we add in the next step
  - Add all those files to git
- Get example data using `dvc get https://github.com/iterative/dataset-registry tutorial/ver/data.zip`
  - This will download some example data (1800 cat/dog pics)
  - Extract the download into `data` folder and delete downloaded zip file
- Add the data folder using DVC instead of git `dvc add data`
  - Follow the instruction (of dvc add data) to add the dvc metadata to git using `git add data.dvc .gitignore`
    - This prevents git from tracking the raw data but tracks only the "references" managed by DVC
- A small test script was added `dvc_python_test/train.py` to test the dataset (i.e. count the elements to indicate the change of size in the raw data)
- Add additional raw data using
  - `dvc get https://github.com/iterative/dataset-registry tutorial/ver/new-labels.zip`
  - Running `dvc status` will show you that the `data` folder was modified.
    - Running `dvc_python_test/train.py` will now also output 2800 elements instead of 1800
  - Running `dvc add data` again will add the additional raw data and update the DVC internal metadata
    - Another `git status` will indicate that by showing that only `data.dvc` was modified
- Normally you would specify a remote storage where the data is located, e.g. AWS S3
  - In this example it was added by pointing to the sample data `dvc remote add -d iterative-reg https://github.com/iterative/dataset-registry`
- You can now try to get the most recent version of the data (or the version from the commit before) by deleting the contents of the data directory and running `dvc pull`
  - depending on the version (an actual git commit) you use you will end up with either 1800 or 2800 pictures (verify it by executing the python script)

For more details on DVC have a look at the great tutorials:

- <https://dvc.org/doc/start>
- <https://dvc.org/doc/start/data-versioning>
- <https://dvc.org/doc/user-guide/what-is-dvc>
