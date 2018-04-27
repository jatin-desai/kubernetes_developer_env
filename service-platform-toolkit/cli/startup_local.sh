#!/usr/bin/env bash

## run this from the SHP base folder (~/sandbox/shp/gitrepo for me)
# Set the shp base folder
export SHP_HOME=$(pushd $(dirname $0)/../.. >/dev/null ; echo ${PWD})
echo "SHP home: ${SHP_HOME}"

printf "\n Do you want to configure cntlm proxy - (y/n) (default - y): ";read proxyflag
if [[ $proxyflag != "n" ]]; then
  USE_PROXY="y"
else
  USE_PROXY="n"
fi

# set docker registry env variable
printf '\n Setting docker registry at localhost(host.docker.internal:5000)'
printf '\nfor the local dev env. the registry will run on the host machine\n'
SHP_DOCKER_REGISTRY='host.docker.internal:5000'


printf "\n2.3 Setting VM driver for minikube to virtualbox or hyperkit"
read_vm_driver
read -p "Select the vm-driver to use - {H}yperkit or {V}irtualBox? (default - virtualbox) " read_vm_driver
case "${read_vm_driver}" in
  "H"|"h")
    VM_DRIVER="hyperkit"
    VM_HOST_IP='192.168.64.1'
    ;;
  "V"|"v")
    VM_DRIVER="virtualbox"
    VM_HOST_IP='192.168.99.1'
    ;;
  *)
    VM_DRIVER="virtualbox"
    VM_HOST_IP='192.168.99.1'
    ;;
esac

echo "Selected VM driver: '${VM_DRIVER}'"

# the node ip used by docker within minikube to talk back to the host
# configured as a part of the dns config - this is configured by VirtualBox


printf "\n2.4 Configure proxy endpoint for minikube to point to host ip from minikube\n"
SHP_NODE_IP=$VM_HOST_IP
SHP_PROXY_URL=http://$SHP_NODE_IP:3128
NO_PROXY_URLS="host.docker.internal,$SHP_NODE_IP,*.hsbc"

# run from SHP_HOME
cd $SHP_HOME

# for clean startup - first stop if it is running
printf "\n2.5 Stop the running minikube cluster to perform clean startup"
minikube stop

# start the minikube cluster
printf "\n2.6 Starting minikube"


if [[ $USE_PROXY == "y" ]]; then
  PROXY_CONFIG=" --docker-env HTTP_PROXY=$SHP_PROXY_URL --docker-env HTTPS_PROXY=$SHP_PROXY_URL --docker-env NO_PROXY=$NO_PROXY_URLS"
else
  PROXY_CONFIG= " "
fi
minikube start --memory=6144 --vm-driver $VM_DRIVER \
--insecure-registry $SHP_DOCKER_REGISTRY $PROXY_CONFIG

printf "\n2.7 minikube status"
minikube status

# list all containers and services in the kubernetes cluster
printf "\n2.8 Kubernetes cluster initializing\n"
kubectl get pods,services --all-namespaces



printf '\n\n********************************************************************************'
printf '\n***************     Service Hosting Platform - Up and Running    ***************'
printf '\n********************************************************************************'
printf '\n***************   Platform Base Domain: local.service.platform   ***************'
printf '\n*******  Dashboard URL: http://local.service.platform/dashboard   *******'
printf '\n*******  Kibana Dashboard: http://local.service.platform/kibana   ******'
printf '\n********************************************************************************\n\n'
