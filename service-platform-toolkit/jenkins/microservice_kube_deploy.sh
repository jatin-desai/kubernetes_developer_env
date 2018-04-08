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


load_team_platform_config() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 3 Load Service Hosting Platform Configuration"
  printf '\n********************************************************************************\n'

  export BASE_CONFIG=$SHP_HOME/service-platform-operations/$SHP_TEAM_NAME/$SHP_TEAM_NAME-config.sh
  export ENV_CONFIG=$SHP_HOME/service-platform-operations/$SHP_TEAM_NAME/$SHP_TEAM_NAME-config-$SHP_TARGET_ENV.sh

  source $BASE_CONFIG
  source $ENV_CONFIG

  export PLATFORM_BASE_DOMAIN=$shp_base_domain
  export APP_NAMESPACE=$k8s_namespace
  export APP_SUBDOMAIN=$app_subdomain
}

load_app_env_params() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 4 Load Application Environment Configuration"
  printf '\n********************************************************************************\n'


  cd $APP_BASEFLDR
  export APP_NAME=$(mvn -o org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.artifactId | grep -v '\[')

}



deploy_app_to_shp_k8s() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 5 Deploy application to Kubernetes cluster"
  printf '\n********************************************************************************\n'


  # Deploy microservice to K8s cluster in the K8S_NAMESPACE
  cd $SHP_HOME/service-platform-operations/$SHP_TEAM_NAME/$APP_NAME
  kubectl apply -f app-deployment-$SHP_TARGET_ENV.yml
  kubectl apply -f app-service-$SHP_TARGET_ENV.yml
  kubectl apply -f app-ingress-$SHP_TARGET_ENV.yml
  kubectl get pods,services,ingress -n=$APP_NAMESPACE

}

print_microservice_domain() {

    printf '\n\n********************************************************************************'
    printf '\n***************             Microservice deployed to             ***************'
    printf '\n*****    http://'$APP_NAME'.'$APP_SUBDOMAIN'.'$PLATFORM_BASE_DOMAIN'/   *****'
    printf '\n********************************************************************************'

}

# execute script

set_shp_env
set_app_env
load_team_platform_config
load_app_env_params
deploy_app_to_shp_k8s
print_microservice_domain
