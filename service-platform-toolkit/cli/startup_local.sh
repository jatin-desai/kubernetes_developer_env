#!/usr/bin/env bash

## run this from the SHP base folder (~/sandbox/shp/gitrepo for me)
# Set the shp base folder
SHP_HOME=$(pwd)

printf "\n Do you want to configure cntlm proxy - (y/n) (default - y): ";read proxyflag
if [[ $proxyflag != "n" ]]; then
  USE_PROXY="y"
else
  USE_PROXY="n"
fi

# set docker registry env variable
printf '\n Setting docker registry at localhost(docker.for.mac.host.internal:5000)'
printf '\nfor the local dev env. the registry will run on the host machine\n'
SHP_DOCKER_REGISTRY='docker.for.mac.host.internal:5000'


printf "\n2.3 Setting VM driver for minikube to virtualbox or hyperkit"
VM_DRIVER="virtualbox"
VM_HOST_IP='192.168.99.1'

# the node ip used by docker within minikube to talk back to the host
# configured as a part of the dns config - this is configured by VirtualBox


printf "\n2.3 Configure proxy endpoint for minikube to point to host ip from minikube\n"
SHP_NODE_IP=$VM_HOST_IP
SHP_PROXY_URL=http://$SHP_NODE_IP:3128
NO_PROXY_URLS="docker.for.mac.host.internal,$SHP_NODE_IP,*.hsbc"

# run from SHP_HOME
cd $SHP_HOME

# for clean startup - first stop if it is running
minikube stop

# start the minikube cluster

if [[ $USE_PROXY == "y" ]]; then
  PROXY_CONFIG=" --docker-env HTTP_PROXY=$SHP_PROXY_URL --docker-env HTTPS_PROXY=$SHP_PROXY_URL --docker-env NO_PROXY=$NO_PROXY_URLS"
else
  PROXY_CONFIG= " "
fi
minikube start --memory=6144 --vm-driver $VM_DRIVER \
--insecure-registry $SHP_DOCKER_REGISTRY $PROXY_CONFIG

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
