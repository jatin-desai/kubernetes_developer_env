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

  export PATH=$PATH:$HOME/tools/hudson.tasks.Maven_MavenInstallation/maven/bin:$HOME/tools/org.jenkinsci.plugins.docker.commons.tools.DockerTool/bin

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
  export SHP_DCR_REGISTRY=$shp_docker_registry
  export APP_NAMESPACE=$k8s_namespace

  export APP_SUBDOMAIN=$app_subdomain
  export APP_CONT_PORT=$container_port
  export APP_SVC_PORT=$service_port
  export APP_INST_CNT=$instance_count
}

load_app_env_params() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 4 Load Application Environment Configuration"
  printf '\n********************************************************************************\n'


  cd $APP_BASEFLDR
  export APP_GROUP_ID=$(mvn -o org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.groupId | grep -v '\[')
  export APP_NAME=$(mvn -o org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.artifactId | grep -v '\[')
  export APP_VERSION=$(mvn -o org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version | grep -v '\[')


  # Set docker env params
  ## Docker app jar is the generated app
  export APP_JAR=target/$APP_NAME-$APP_VERSION.jar

  ## Docker image repo maps to group id from maven pom
  ## Docker app name maps to artifact id from pom
  ## Docker image version maps to app version in pom
  export APP_BASE_DOCKER_TAG=$APP_GROUP_ID/$APP_NAME:$APP_VERSION


  export APP_DCK_REPO_TAG=$SHP_DCR_REGISTRY/$APP_BASE_DOCKER_TAG

  printf '\n\n********************************************************************************\n'
  printf "\n1. APP_GROUP_ID = "
  echo $APP_GROUP_ID
  printf "\n2. APP_NAME= "
  echo $APP_NAME
  printf "\n3. APP_VERSION = "
  echo $APP_VERSION
  printf "\n4. APP_JAR = "
  echo $APP_JAR
  printf "\n5. APP_BASE_DOCKER_TAG = "
  echo $APP_BASE_DOCKER_TAG
  printf "\n6. APP_DCK_REPO_TAG = "
  echo $APP_DCK_REPO_TAG
  printf '\n********************************************************************************\n'

}


build_ms_docker_image() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 5 Build Application Docker Image and Push to Repo"
  printf '\n********************************************************************************\n'

  # Create docker image of the microservice
  # go to microservice base folder - build folder
  cd $APP_BASEFLDR

  # set docker env. to use minikube
  ## will mean that all docker commands will run effectively inside minikube
  # eval $(minikube docker-env)

  printf "5.1 Starting creation of Docker Image for - "$APP_BASEFLDR/$APP_JAR"\n"
  # Create docker image of the application - use the standard java app docker file provided
  sudo docker build -f $SHP_HOME/service-platform-toolkit/utils/docker/app-images/JavaAppDockerfile -t $APP_BASE_DOCKER_TAG --build-arg JAR_FILE=$APP_JAR $APP_BASEFLDR

  printf "\n5.2 Docker image created - "$APP_BASE_DOCKER_TAG"\n"

  # test app

  ## run in first console
  # docker run -p 8080:8080 $APP_REPO/$APP_NAME:$APP_VERSION

  # run in a different console
  # minikube ssh
  # test url for hello-world app - from inside minikube
  # curl -X GET http://localhost:8080/hello

  # terminate docker run process

  # tag and push the image to the docker registry
  printf "\n5.3 Uploading docker image to Docker Repository - "$APP_DCK_REPO_TAG"\n"
  sudo docker tag $APP_BASE_DOCKER_TAG $APP_DCK_REPO_TAG
  sudo docker push $APP_DCK_REPO_TAG
}



# execute script

set_shp_env
set_app_env
load_team_platform_config
load_app_env_params
build_ms_docker_image
