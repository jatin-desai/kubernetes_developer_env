# A Dockerfile for creating an Elasticsearch instance for use inside minikube
# using 2.4.0 version to avoid issues related to vm memory setting inside minikube
# copied from inovex/kubernetes-logging git project

# docker build -t jatindesai/elasticsearch:2.4.0 .

FROM java:openjdk-8-jre
MAINTAINER Jatin Desai "jatindesai@yahoo.com"
ENV DEBIAN_FRONTEND noninteractive

RUN useradd elasticsearch

RUN apt-get update && \
    apt-get install -y curl && \
    apt-get clean

RUN cd / && \
    curl -OL https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-2.4.0.tar.gz && \
    tar xf elasticsearch-2.4.0.tar.gz && \
    rm elasticsearch-2.4.0.tar.gz && \
    mv /elasticsearch-2.4.0 /elasticsearch

RUN mkdir -p /elasticsearch/config/templates

COPY elasticsearch.yml /elasticsearch/config/elasticsearch.yml
COPY template-k8s-logstash.json /elasticsearch/config/templates/template-k8s-logstash.json
COPY run.sh /
RUN chmod +x /run.sh
COPY elasticsearch_logging_discovery /

RUN mkdir -p /data && chown -R elasticsearch:elasticsearch /data && chown -R elasticsearch:elasticsearch /elasticsearch
USER elasticsearch

VOLUME ["/data"]
EXPOSE 9200 9300

CMD ["/run.sh"]
