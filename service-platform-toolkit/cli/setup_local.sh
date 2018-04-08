#!/usr/bin/env bash

echo_prereqs() {

  echo "
    1. Ensure that cntlm is setup on your machine - with the proxy configured at http://127.0.0.1:3128/
    2. Configure docker to use the cntlm proxy
    3. copy the internal-root-ca.pem file from shp-hsbc-utils/security to $HOME/bin folder
    4. add internal-root-ca.pem to your docker config (“tlscacert” : “/Users/<userid>/bin/internal-root-ca.pem”)
    5. Ensure that the DNS nameservice is configured at /etc/resolver/<domain> for your specific dns (e.g. local.service.platform)
    Press y+enter to continue... enter to exit
  "
  # script : echo "nameserver 127.0.0.1" >> /etc/resolver/local.service.platform

  read cont
  if [[ $cont != "y" ]]; then
    exit
  fi
}

clean_slate() {

  echo "
    This script will delete any existing minikube env and the existing service platform docker registry instance
    Press y+enter to continue... enter to exit
  "
  read cleanup
  if [[ $cleanup != "y" ]]; then
    exit
  else
    minikube stop
    minikube delete
    DNS_CONT_ID=$(docker ps | grep serviceplatformdns | awk '{print $1}')
    docker stop $DNS_CONT_ID
    docker rm $DNS_CONT_ID
    REGISTRY_CONT_ID=$(docker ps | grep serviceplatformregistry | awk '{print $1}')
    docker stop $REGISTRY_CONT_ID
    docker rm $REGISTRY_CONT_ID

  fi
  printf '\n Clean Slate Complete ';read cont
}

set_env () {

  printf '\n\n********************************************************************************\n'
  printf "Stage 1: Setting the local env. "
  printf '\n********************************************************************************\n'

  ## run this from the SHP base folder (~/sandbox/shp/gitrepo for me)
  # Set the shp base folder
  printf "\n1.1 Setting up the Service Hosting Platform Home Folder" $(pwd)
  SHP_HOME=$(pwd)


  # set docker registry env variable
  printf "\n1.2 Setting docker registry at localhost(docker.for.mac.host.internal:5000) - for the local dev env. the registry will run on the host machine"
  SHP_DOCKER_REGISTRY='docker.for.mac.host.internal:5000'

  # the node ip used by docker within minikube to talk back to the host
  # configured as a part of the dns config - this is configured by VirtualBox
  SHP_NODE_IP='192.168.99.1'

  SHP_PROXY_URL=http://$SHP_NODE_IP:3128

  printf "\n1.3 Setting the base hsbc docker repository name - digital"
  printf "This is more as a reference and the appropriate docker repository structure will need to be agreed"
  SHP_BASE_REPO='digital'

  printf '\n********************************************************************************\n'
  printf "Stage 1 Complete \n"
  printf '\n********************************************************************************\n\n'
}

setup_docker_registry() {

  echo "\Stage 2 - Initialize Docker Registry"

  echo "\n*** Setting up local docker registry\n"
  docker-compose -f $SHP_HOME/service-platform-toolkit/utils/docker/registry.yml -p service-platform-registry up --remove-orphans -d

  # validate registry service is up and running
  echo "Docker Registry starting up"
  docker ps | grep registry

  printf '\n Docker Registry Created ';read cont
}

init_minikube() {

  echo "\Stage 2 - Initialize Minikube"
  # run from SHP_HOME
  cd $SHP_HOME

  # start the minikube cluster
  echo "\n2.1 Starting minikube"

#  minikube start --insecure-registry localhost:5000

  minikube start --memory=6144 \
  --insecure-registry "docker.for.mac.host.internal:5000"
  #\
  #--docker-env HTTP_PROXY=$SHP_PROXY_URL \
  #--docker-env HTTPS_PROXY=$SHP_PROXY_URL \
  #--docker-env NO_PROXY="docker.for.mac.host.internal,$SHP_NODE_IP"

  echo "\n2.3 Configure minikube to route docker requests to host ip"
  minikube ssh "sudo sh -c 'echo $SHP_NODE_IP docker.for.mac.host.internal >> /etc/hosts'"

  printf '\nMinikube created ';read cont

  # set docker env. to use minikube
  # will mean that all docker commands will run effectively inside minikube
#  echo "\n2.2 setting the docker env. config to point to minikube"
#  eval $(minikube docker-env)

  # setup the docker registry inside the minikube environment
#  echo "\n2.3 setup the docker registry inside minikube"
#  docker run -d -p 5000:5000 --restart=always --name registry   -v /data/docker-registry:/var/lib/registry registry:2

  # validate registry service is up and running
#  echo "Docker Registry starting up"
#  docker ps | grep registry

  # list all containers and services in the kubernetes cluster
  echo "Kubernetes cluster initializing\n"
  kubectl get pods,services --all-namespaces

}

setup_dns() {
  # each platform instance will have a base domain - e.g. local.service.platform
  # further each namespace will have it's own subdomain - with the same name

  # Setup DNS resolution to the minikube cluster

  echo "Ensure that the dns nameserver is configured at /etc/resolver/<minikube base domain> pointing to 127.0.0.1"
  echo "e.g. script : echo \"nameserver 127.0.0.1\" >> local.service.platform"
  echo "Press enter to continue... "
  read cont

  MINIKUBE_IP=$(minikube ip) SHP_NODE_IP=$SHP_NODE_IP docker-compose -f $SHP_HOME/service-platform-toolkit/utils/kubernetes/kube-config/dns.yml -p service-platform-dns up -d
}

configure_dashboard(){
  # Enable ingress in minikube
  minikube addons enable ingress

  # the subdomain for kube-system and other kubernetes system services will be system.<base domain> - system.local.service.platform - for me

  # Enable Kubernetes Dashboard Ingress - both approaches shown for demo -
  # Option 1 - dashboard gets a domain
  kubectl apply -f $SHP_HOME/service-platform-toolkit/utils/kubernetes/kube-config/dashboard-ingress-domain.yml
  #curl -X GET http://dashboard.system.local.service.platform
  # Option 2 - dashboard is a route on the base domain for the platform instance
  kubectl apply -f $SHP_HOME/service-platform-toolkit/utils/kubernetes/kube-config/dashboard-ingress-path.yml
  #curl -X GET http://system.local.service.platform/dashboard

  printf '\n minikube up and running ';read cont

}


configure_fluentd_elasticsearch_kibana() {

  cd $SHP_HOME/service-platform-toolkit/utils/kube-logging/config/
  kubectl apply -f es-controller.yaml
  kubectl apply -f es-service.yaml
  kubectl apply -f kibana-controller.yaml
  kubectl apply -f kibana-service.yaml
  kubectl apply -f kibana-ingress-domain.yml
  kubectl apply -f fluentd-daemonset-elasticsearch-syslog.yaml

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
#configure_fluentd_elasticsearch_kibana
echo_setup_complete
