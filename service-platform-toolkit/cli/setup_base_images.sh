#!/usr/bin/env bash


set_env () {

  printf '\n\n********************************************************************************\n'
  printf "Stage 1: Setting the local env. "
  printf '\n********************************************************************************\n'

  ## run this from the SHP base folder (~/sandbox/shp/gitrepo for me)
  # Set the shp base folder
  printf "\n1.1 Setting up the Service Hosting Platform Home Folder" $(pwd)
  export SHP_HOME=$(pushd $(dirname $0)/../.. >/dev/null ; echo ${PWD})
  echo "SHP home: ${SHP_HOME}"

  printf "\n Do you want to configure cntlm proxy - (y/n) (default - y): ";read proxyflag
  if [[ $proxyflag != "n" ]]; then
    USE_PROXY="y"
  else
    USE_PROXY="n"
  fi

  # set docker registry env variable
  printf "\n1.2 Setting docker registry at localhost(host.docker.internal:5000) - for the local dev env. the registry will run on the host machine"
  SHP_DOCKER_REGISTRY='host.docker.internal:5000'


  printf "\n 2.3 Setting VM driver for minikube to virtualbox or hyperkit \n"
  local read_vm_driver
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

  # the node ip used by docker within minikube to talk back to the host
  # configured as a part of the dns config
  # virtualbox host ip

  printf "\n 2.4 Configure proxy endpoint for minikube to point to host ip from minikube\n"
  SHP_NODE_IP=$VM_HOST_IP

  SHP_PROXY_URL=http://$SHP_NODE_IP:3128

  if [[ $USE_PROXY == "y" ]]; then
    export http_proxy=$SHP_PROXY_URL
    export https_proxy=$SHP_PROXY_URL
    export HTTP_PROXY=$SHP_PROXY_URL
    export HTTPS_PROXY=$SHP_PROXY_URL
  fi


  printf "\n1.3 Setting the base docker repository name - digital\n"
  printf "\nThis is more as a reference and the appropriate docker repository structure will need to be agreed\n"
  SHP_BASE_REPO='digital'

  printf '\n********************************************************************************\n'
  printf "Stage 1 Complete \n"
  printf '\n********************************************************************************\n\n'
}



build_docker_base_image() {
  # build base image
  cd $SHP_HOME/service-platform-toolkit/docker-images/base-images

  # set docker env. to use minikube
  # will mean that all docker commands will run effectively inside minikube
  echo "\n setting the docker env. config to point to minikube"
  eval $(minikube docker-env)

  APPD_AGENT=appd_agent.tar
  CERT_KEYSTORE=internal-certs-dummy.jks

  # NOTE : this will need to be externalized and point to the correct password for the keystore being specified
  KEYSTORE_PASSWORD="changeme"

  cp $SHP_HOME/shp-hsbc-utils/appd/$APPD_AGENT .
  cp $SHP_HOME/shp-hsbc-utils/security/$CERT_KEYSTORE .

  DOCKER_BUILD_ARGS="--build-arg APPD_AGENT=$APPD_AGENT --build-arg CERT_KEYSTORE=$CERT_KEYSTORE --build-arg KEYSTORE_PASSWORD=$KEYSTORE_PASSWORD"

  docker build -f JavaBaseDockerfile -t $SHP_BASE_REPO/shp-openjdk:8-jdk-alpine $DOCKER_BUILD_ARGS .

  # push image to docker repository
  docker tag $SHP_BASE_REPO/shp-openjdk:8-jdk-alpine $SHP_DOCKER_REGISTRY/$SHP_BASE_REPO/shp-openjdk:8-jdk-alpine
  docker push $SHP_DOCKER_REGISTRY/$SHP_BASE_REPO/shp-openjdk:8-jdk-alpine

  rm $CERT_KEYSTORE
  rm $APPD_AGENT

}


# execute script
set_env
build_docker_base_image
