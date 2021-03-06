#!/usr/bin/env bash


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

  # export http_proxy=$SHP_PROXY_URL
  # export https_proxy=$SHP_PROXY_URL
  # export HTTP_PROXY=$SHP_PROXY_URL
  # export HTTPS_PROXY=$SHP_PROXY_URL


  printf "\n1.3 Setting the base docker repository name - digital"
  printf "This is more as a reference and the appropriate docker repository structure will need to be agreed"
  SHP_BASE_REPO='digital'

  printf '\n********************************************************************************\n'
  printf "Stage 1 Complete \n"
  printf '\n********************************************************************************\n\n'
}



build_docker_base_image() {
  # build base image
  cd $SHP_HOME/service-platform-toolkit/utils/docker/base-images

  # set docker env. to use minikube
  # will mean that all docker commands will run effectively inside minikube
  echo "\n setting the docker env. config to point to minikube"
  # eval $(minikube docker-env)

  APPD_AGENT=appd_agent.tar
  INT_CERT_KEYSTORE=internal-certs-dummy.jks

  cp $SHP_HOME/shp-hsbc-utils/security/$INT_CERT_KEYSTORE .

  sudo docker build -f JavaBaseDockerfile -t $SHP_BASE_REPO/shp-openjdk:8-jdk-alpine --build-arg APPD_AGENT=$APPD_AGENT --build-arg INT_CERT_KEYSTORE=$INT_CERT_KEYSTORE .

  # push image to docker repository
  sudo docker tag $SHP_BASE_REPO/shp-openjdk:8-jdk-alpine $SHP_DOCKER_REGISTRY/$SHP_BASE_REPO/shp-openjdk:8-jdk-alpine
  sudo docker push $SHP_DOCKER_REGISTRY/$SHP_BASE_REPO/shp-openjdk:8-jdk-alpine



  # rm internal-certs-dummy.jks

}


# execute script
set_env
build_docker_base_image
