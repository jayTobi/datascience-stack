# Data Science Stack using MLFlow, DVC and ELK
## Overview
This guide helps you to set up a stack containing useful tools 
for data science projects.
It focuses on additional tools to support the process as much as
possible. This includes:
- MLFLow for the ML lifecycle, e.g. tracking metrics
- DVC for managing and versioning data
- ELK for managing logs and providing a UI for searching

To combine everything into an easily executable environment we will
use Docker to manage the different components.

## Prerequisite
To follow this guide you need some additional resources which might not be
available on your system. Please have a look at their documentation to get started.

- Docker <https://docs.docker.com/engine/>
- Docker Compose <https://docs.docker.com/compose/>

For development Visual Studio Code (VS Code) is used: <https://code.visualstudio.com/>

## Docker and Docker Compose

To run the environment inside docker just open a terminal, browse to the folder
containing the ```docker-compose.yml``` and run the following command: 
```docker-compose up -d``` 
(-d runs the containers in detach mode and is optional)

## ELK / EFK stack (Elasticsearch Logstash/Fluentd Kibana)
The Elastic Stack provides different products for log management and analysis.
It's only one possibility but has a broad adoption currently so we use it here
exemplary.
Product details can be found here: <https://www.elastic.co/>

The ```docker-compose.yml``` inside this repo includes everything to run the stack. 

A more detailed guide for setting up the ELK stack using docker can be found here <https://www.elastic.co/guide/en/elastic-stack-get-started/current/get-started-docker.html>.

After everything started successfully you can access Kibana using a web browser and the URL <http://localhost:5601>


If the environment can not be started, e.g. Kibana can not connect to elastic search - look inside the logs for the elasticsearch container.

You might find something like "max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]" if so check your OS documentation on how to change this.
(A solution can also be found here <https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html>)

## Python logging

An important aspect of longer running experiments is logging information. This will be helpful for understanding the program flow and finding errors.
Using ELK these information can be accessed easily and in a long term.

We configure Python logging and make the output accessible
for ELK.
Details on the Python config can be found here <https://docs.python.org/3/howto/logging.html#configuring-logging>

If you get a "KeyError: 'formatters'" your configuration can not be found by Python (it is searching in the current working directory (os.getcwd()) - check your path and try again.
## fluentd and ElasticSearch (EFK stack)

To send our logging output to ElasticSearch we use fluentd <https://docs.fluentd.org/>.
(Another possibility would be using FileBeat "belonging" to the ELK stack).

For installing fluentd follow the appropriate guide on <https://docs.fluentd.org/installation>.

### Configuration

The fluentd service will be running on the same machine as the Python code itself - although it would be possible do include this into a separate Docker container as well.

Open the file ```/etc/td-agent/td-agent.conf``` and replace the content, probably making a backup, with the following content (as seen in the ```td-agent.conf``` in this repo)
```
<source>
  @type forward
  port 24224
</source>

<match ds.**>
  @type elasticsearch
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
```sudo systemctl status td-agent.service```.

You can check the output of the fluentd agent by inspecting the following file, e.g. using 
```tail -f /var/log/td-agent/td-agent.log```

If the start and connection to Elasticsearch (ES) is successful you should see something like
```
GET http://127.0.0.1:9200/ [status:200, request:0.002s, query:n/a]
```
Later you can also verify that the LOG messages from your Python code are send to ES by looking for lines like:
```
POST http://127.0.0.1:9200/_bulk [status:200, request:0.304s, query:0.298s]
```
These are triggered periodically depending on the configured flush_interval above.

### Using fluentd and Python logging

Here we show 2 different versions of the logging configuration.

A more manual approach that can be found inside the file ```logging/fluentd_test.py``` and the easier and probably more suitable way using **external** configuration (logging.yml) can be found in ```logging/fluentd_with_config.py```.

The third code inside ```logging/logging_test.py``` just configures standard Python logging without fluentd.

You can just run the Python scripts and check the fluentd log and the Kibana Web UI.