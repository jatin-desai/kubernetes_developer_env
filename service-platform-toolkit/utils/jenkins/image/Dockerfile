# docker build -t jatindesai/jenkins:2.60.3 .
# adding jenkins user with sudo access to be able to access docker cli

FROM jenkins:2.60.3
MAINTAINER Jatin Desai <jatindesai@yahoo.com>

USER root
RUN apt-get update \
      && apt-get install -y sudo curl \
      && rm -rf /var/lib/apt/lists/*
RUN echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers


RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.10.0/bin/bin/linux/amd64/kubectl && chmod +x kubectl && mv kubectl /usr/local/bin/
# COPY ./kubectl /usr/local/bin/
# RUN chmod +x /usr/local/bin/kubectl

USER jenkins
COPY plugins.txt /usr/share/jenkins/plugins.txt
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/plugins.txt
