#!/usr/bin/env bash

### Usage ./service-platform-toolkit/cli/microservice.sh from the SHP home folder
# e.g. ./service-platform-toolkit/cli/microservice.sh

set_shp_env() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 1 Setting working env"
  printf '\n********************************************************************************\n'
  ## run this from the SHP base folder (~/sandbox/shp/gitrepo for me)
  # Set the shp base folder
  export SHP_HOME=$(pwd)

  export PATH=$PATH:$HOME/tools/hudson.tasks.Maven_MavenInstallation/M3/bin

  # the node ip used by docker within minikube to talk back to the host
  # configured as a part of the dns config - this is configured by VirtualBox
  # SHP_NODE_IP='192.168.99.1'

  # SHP_PROXY_URL=http://$SHP_NODE_IP:3128

  # export http_proxy=$SHP_PROXY_URL
  # export https_proxy=$SHP_PROXY_URL
  # export HTTP_PROXY=$SHP_PROXY_URL
  # export HTTPS_PROXY=$SHP_PROXY_URL


  printf '\n********************************************************************************\n'
  printf "Stage 1 Complete \n"
  printf '\n********************************************************************************\n\n'

}


set_app_env() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 2 - Collecting Application-specific configuration"
  printf '\n********************************************************************************\n'

  # configure the team name - which will determine the base configuration details - <team_name>-config.sh
  export SHP_TEAM_NAME='platform'

  # configure application base folder - which has the pom.xml
  export SHP_TARGET_ENV='local'

  # configure application base folder - which has the pom.xml
  export APP_BASEFLDR=$SHP_HOME'/platform-example-spring'

}

build_microservice_pkg() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 3 Build and Package Application"
  printf '\n********************************************************************************\n'

  # Build microservice
  # build app
  cd $APP_BASEFLDR
  mvn clean package

}



# execute script
set_shp_env
set_app_env
build_microservice_pkg
