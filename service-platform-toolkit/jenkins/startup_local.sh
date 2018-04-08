#!/usr/bin/env bash

## run this from the SHP base folder (~/sandbox/shp/gitrepo for me)
# Set the shp base folder
SHP_HOME=$(pwd)

# set docker registry env variable
printf '\n Setting docker registry at localhost(docker.for.mac.host.internal:5000)'
printf '\nfor the local dev env. the registry will run on the host machine\n'
SHP_DOCKER_REGISTRY='docker.for.mac.host.internal:5000'

# the node ip used by docker within minikube to talk back to the host
# configured as a part of the dns config - this is configured by VirtualBox
SHP_NODE_IP='192.168.99.1'

SHP_PROXY_URL=http://$SHP_NODE_IP:3128

# run from SHP_HOME
cd $SHP_HOME

# for clean startup - first stop if it is running
minikube stop

# start the minikube cluster

minikube start --memory=6144 \
--insecure-registry "docker.for.mac.host.internal:5000" \
--docker-env HTTP_PROXY=$SHP_PROXY_URL \
--docker-env HTTPS_PROXY=$SHP_PROXY_URL \
--docker-env NO_PROXY="docker.for.mac.host.internal,$SHP_NODE_IP"

# set docker env. to use minikube
# will mean that all docker commands will run effectively inside minikube
eval $(minikube docker-env)

# validate registry service is up and running
# docker ps | grep registry

# list all containers and services in the kubernetes cluster
# kubectl get pods,services --all-namespaces

echo '********************************************************************************'
echo '***************     Service Hosting Platform - Up and Running    ***************'
echo '********************************************************************************'
echo '***************   Platform Base Domain: local.service.platform   ***************'
echo '*******  Dashboard URL: http://dashboard.system.local.service.platform   *******'
echo '********************************************************************************'
