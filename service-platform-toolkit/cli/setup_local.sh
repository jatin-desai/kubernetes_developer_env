#!/usr/bin/env bash

echo_prereqs() {

  printf '\n\n********************************************************************************\n'
  printf " Stage 0: Welcome to setting up of Kubenetes Development Environment using minikube "
  printf '\n********************************************************************************\n'

  printf "\n Is this a dry run : default=n "; read dryrun

  if [[ $dryrun == "y" ]]; then
    MINIKUBE_CMD="echo minikube"
    DOCKER_CMD="echo docker"
    DOCKER_COMPOSE_CMD="echo docker-compose"
    KUBECTL_CMD="echo kubectl"
  else
    MINIKUBE_CMD="minikube"
    DOCKER_CMD="docker"
    DOCKER_COMPOSE_CMD="docker-compose"
    KUBECTL_CMD="kubectl"
  fi

  echo "
    1. Ensure that cntlm is setup on your machine - with the proxy configured at http://127.0.0.1:3128/
    2. Configure docker to use the cntlm proxy
    3. copy the internal-root-ca.pem file from shp-hsbc-utils/security to $HOME/bin folder
    4. add internal-root-ca.pem to your docker config (“tlscacert” : “/Users/<userid>/bin/internal-root-ca.pem”)
    5. Ensure that the DNS nameservice is configured at /etc/resolver/<domain> for your specific dns (e.g. local.service.platform)
    Press enter to continue... Ctrl+C to exit
  "
  read cont

  printf "\n Do you want to configure cntlm proxy - (y/n) (default - y): ";read proxyflag
  if [[ $proxyflag != "n" ]]; then
    USE_PROXY="y"
  else
    USE_PROXY="n"
  fi

}

clean_slate() {

  printf '\n\n********************************************************************************\n'
  printf " Stage 1: Clean-up any existing minikube environment and dependent docker containers "
  printf '\n********************************************************************************\n'

  echo "
    This script will delete any existing minikube env and the existing service platform docker registry instance
    Press enter to continue... Ctrl+C to exit
  "
  read cleanup

  printf "\n Deleting minikube \n"
  $MINIKUBE_CMD stop
  $MINIKUBE_CMD delete

  printf "\n\n Deleting DNS Server \n"
  DNS_CONT_ID=$(docker ps | grep serviceplatformdns | awk '{print $1}')
  $DOCKER_CMD stop $DNS_CONT_ID
  $DOCKER_CMD rm $DNS_CONT_ID

  printf "\n\n Deleting local docker registry \n"
  REGISTRY_CONT_ID=$(docker ps | grep serviceplatformregistry | awk '{print $1}')
  $DOCKER_CMD stop $REGISTRY_CONT_ID
  $DOCKER_CMD rm $REGISTRY_CONT_ID

  printf '\n Clean Slate Complete ';read cont

  printf '\n\n********************************************************************************\n'
  printf " Stage 1 COMPLETE "
  printf '\n********************************************************************************\n'

}

set_env () {

  printf '\n\n********************************************************************************\n'
  printf "Stage 2: Setting the local env. "
  printf '\n********************************************************************************\n'

  ## run this from the SHP base folder (~/sandbox/shp/gitrepo for me)
  # Set the shp base folder
  printf "\n2.1 Setting up the Service Hosting Platform Home Folder" $(pwd) "\n"
  SHP_HOME=$(pwd)

  SHP_DOMAIN_NAME="local.service.platform"

  # set docker registry env variable
  printf "\n2.2 Setting docker registry at localhost(docker.for.mac.host.internal:5000) - for the local dev env. the registry will run on the host machine\n"
  SHP_DOCKER_REGISTRY='docker.for.mac.host.internal:5000'

  printf "\n2.3 Setting VM driver for minikube to virtualbox or hyperkit"
  VM_DRIVER="virtualbox"
  VM_HOST_IP='192.168.99.1'

  # VM_DRIVER="hyperkit"
  # VM_DRIVER="hyperkit"
  # VM_HOST_IP='192.168.64.1'

  # the node ip used by docker within minikube to talk back to the host
  # configured as a part of the dns config
  # virtualbox host ip

  printf "\n2.3 Configure proxy endpoint for minikube to point to host ip from minikube\n"
  SHP_NODE_IP=$VM_HOST_IP
  SHP_PROXY_URL=http://$SHP_NODE_IP:3128
  NO_PROXY_URLS="docker.for.mac.host.internal,$SHP_NODE_IP,*.hsbc,*.platform"


  printf '\n********************************************************************************\n'
  printf "Stage 2 Env Pre-Config COMPLETE"
  printf '\n********************************************************************************\n\n'
}

setup_docker_registry() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 3: Initialize local Docker Registry (on host machine)"
  printf '\n********************************************************************************\n'

  echo "\n3.1 Setting up local docker registry\n"
  $DOCKER_COMPOSE_CMD -f $SHP_HOME/service-platform-toolkit/utils/docker-config/registry.yml -p service-platform-registry up --remove-orphans -d

  # validate registry service is up and running
  echo "3.2 Docker Registry status"
  $DOCKER_CMD ps | grep registry

  printf '\n\n********************************************************************************\n'
  printf "Stage 3 Docker Registry Setup COMPLETE"
  printf '\n********************************************************************************\n'
}

init_minikube() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 4: Initialize Kubernetes Cluster - minikube"
  printf '\n********************************************************************************\n'

  # run from SHP_HOME
  cd $SHP_HOME

  # start the minikube cluster
  echo "\n4.1 Starting minikube"

#  minikube start --insecure-registry localhost:5000

  if [[ $USE_PROXY == "y" ]]; then
    PROXY_CONFIG=" --docker-env HTTP_PROXY=$SHP_PROXY_URL --docker-env HTTPS_PROXY=$SHP_PROXY_URL --docker-env NO_PROXY=$NO_PROXY_URLS"
  else
    PROXY_CONFIG= " "
  fi
  $MINIKUBE_CMD start --memory=6144 --vm-driver $VM_DRIVER \
  --insecure-registry $SHP_DOCKER_REGISTRY $PROXY_CONFIG

  echo "\n4.2 minikube status"
  $MINIKUBE_CMD status

  echo "\n4.3 Configure minikube to route docker requests to host ip - required by docker to pull images"
  $MINIKUBE_CMD ssh "sudo sh -c 'echo $SHP_NODE_IP docker.for.mac.host.internal >> /etc/hosts'"

  # Enable ingress in minikube
  echo "\n4.4 Enable Ingress Controller on minikube"
  $MINIKUBE_CMD addons enable ingress


  printf '\nMinikube created; Press Enter to continue...';read cont

  # list all containers and services in the kubernetes cluster
  printf "\n4.5 Kubernetes cluster initializing\n"
  $KUBECTL_CMD get pods,services --all-namespaces

  printf '\n\n********************************************************************************\n'
  printf "Stage 4 Kubernetes Cluster Initialization COMPLETE"
  printf '\n********************************************************************************\n'

}

setup_dns() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 5: Setup local DNS Server"
  printf '\n********************************************************************************\n'

  # each platform instance will have a base domain - e.g. local.service.platform
  # further each namespace will have it's own subdomain - with the same name

  # Setup DNS resolution to the minikube cluster

  echo "Ensure that the dns nameserver is configured at /etc/resolver/<minikube base domain> pointing to 127.0.0.1"
  echo "e.g. script : echo nameserver 127.0.0.1 >> local.service.platform"
  echo "Press enter to continue... "
  read cont

  printf "\n Creating DNS Server Docker container\n"
  MINIKUBE_IP=$(minikube ip) SHP_NODE_IP=$SHP_NODE_IP SHP_DOMAIN_NAME=$SHP_DOMAIN_NAME $DOCKER_COMPOSE_CMD -f $SHP_HOME/service-platform-toolkit/utils/docker-config/dns.yml -p service-platform-dns up -d

  printf '\n\n********************************************************************************\n'
  printf "Stage 5: DNS Server Setup COMPLETE"
  printf '\n********************************************************************************\n'

}

configure_dashboard(){

  printf '\n\n********************************************************************************\n'
  printf "Stage 6: Configure Kubernetes Dashboard"
  printf '\n********************************************************************************\n'

  # the subdomain for kube-system and other kubernetes system services will be system.<base domain> - system.local.service.platform - for me
  # Enable Kubernetes Dashboard Ingress - both approaches shown for demo -

  # Option 1 - dashboard gets a domain
  printf "\n Option 1 - Configuring http://dashboard.system.local.service.platform "
  $KUBECTL_CMD apply -f $SHP_HOME/service-platform-toolkit/utils/kube-config/system/dashboard-ingress-domain.yml
  #curl -X GET http://dashboard.system.local.service.platform

  # Option 2 - dashboard is a route on the base domain for the platform instance
  printf "\n Option 2 - Configuring http://system.local.service.platform/dashboard"
  $KUBECTL_CMD apply -f $SHP_HOME/service-platform-toolkit/utils/kube-config/system/dashboard-ingress-path.yml
  #curl -X GET http://system.local.service.platform/dashboard

  printf '\n\n********************************************************************************\n'
  printf "Stage 6: Kubernetes Dashboard Config COMPLETE"
  printf '\n********************************************************************************\n'

}


configure_fluentd_elasticsearch_kibana() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 7: Configure Platform Services - Logging "
  printf '\n********************************************************************************\n'


  cd $SHP_HOME/service-platform-toolkit/utils/kube-config/services/logging
  printf "\n7.1 Setting up elasticsearch \n"
  $KUBECTL_CMD apply -f es-kibana/es-controller.yaml
  $KUBECTL_CMD apply -f es-kibana/es-service.yaml

  printf "\n7.2 Setting up kibana \n"
  $KUBECTL_CMD apply -f es-kibana/kibana-controller.yaml
  $KUBECTL_CMD apply -f es-kibana/kibana-service.yaml

  printf "\n7.3 Configuring Kibana route - http://kibana.platform.local.service.platform/ \n"
  $KUBECTL_CMD apply -f es-kibana/kibana-ingress-domain.yml

  printf "\n7.4 Configuring fluentd daemonset \n"
  # Set 1 - k8s system logging to es-kibana; platform services and app logging to syslog
  $KUBECTL_CMD apply -f fluentd/es-sl/fluentd-configmap-elasticsearch-syslog.yaml
  $KUBECTL_CMD apply -f fluentd/es-sl/fluentd-daemonset-elasticsearch-syslog.yaml

  # Set 2 - all logging to es & kibana
  # kubectl apply -f fluentd/es/fluentd-configmap-elasticsearch.yaml
  # kubectl apply -f fluentd/es/fluentd-daemonset-elasticsearch.yaml

  # Set 3 - k8s logging to stdout; platform services and app logging to syslog
  # kubectl apply -f fluentd/sl/fluentd-configmap-syslog.yaml
  # kubectl apply -f fluentd/sl/fluentd-daemonset-syslog.yaml


  printf '\n\n********************************************************************************\n'
  printf "Stage 7: Platform Services Config COMPLETE "
  printf '\n********************************************************************************\n'

}


echo_setup_complete() {
  printf '\n\n********************************************************************************'
  printf '\n***************     Service Hosting Platform - Up and Running    ***************'
  printf '\n********************************************************************************'
  printf '\n***************   Platform Base Domain: local.service.platform   ***************'
  printf '\n*******  Dashboard URL: http://dashboard.system.local.service.platform   *******'
  printf '\n*******  Kibana Dashboard: http://kibana.system.local.service.platform   ******'
  printf '\n********************************************************************************\n\n'
}

# execute script

echo_prereqs
clean_slate
set_env
setup_docker_registry
init_minikube
setup_dns
configure_dashboard
configure_fluentd_elasticsearch_kibana
echo_setup_complete
