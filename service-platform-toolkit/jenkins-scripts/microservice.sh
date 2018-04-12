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

  export PATH=$PATH:$HOME/tools/hudson.tasks.Maven_MavenInstallation/M3/bin:$HOME/tools/org.jenkinsci.plugins.docker.commons.tools.DockerTool/bin

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

startup() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 2 Starting minikube cluster"
  printf '\n********************************************************************************\n'

  source $SHP_HOME/service-platform-toolkit/cli/startup_local.sh
}

set_app_env() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 3 - Collecting Application-specific configuration"
  printf '\n********************************************************************************\n'

  # configure the team name - which will determine the base configuration details - <team_name>-config.sh
  printf '\nSpecify the Namespace used for config - (default-platform) : '
  read teamname
  if [ -z "$teamname" ];
  then
    printf "\nteamname env not provided - using platform \n"
    export SHP_TEAM_NAME='platform'
  else
    export SHP_TEAM_NAME=$teamname
  fi

  # configure application base folder - which has the pom.xml
  printf '\nSpecify the Service Hosting Platform Target Environment - local / dev / prod (default-local): '
  read targetenv
  if [ -z "$targetenv" ];
  then
    printf "\ntarget env not provided - using local \n"
    export SHP_TARGET_ENV='local'
  else
    export SHP_TARGET_ENV=$targetenv
  fi

  # configure application base folder - which has the pom.xml
  printf '\nSpecify the microservice application pom folder name : (default-platform-example-spring)'
  read aapbasefldr
  if [ -z "$aapbasefldr" ];
  then
    printf "\nfolder name not provided - using platform-example-spring \n"
    export APP_BASEFLDR=$SHP_HOME'/platform-example-spring'
  else
    export APP_BASEFLDR=$SHP_HOME'/'$aapbasefldr
  fi
}

load_team_platform_config() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 4 Load Service Hosting Platform Configuration"
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
  printf "Stage 5 Load Application Environment Configuration"
  printf '\n********************************************************************************\n'


  cd $APP_BASEFLDR
  echo $(pwd)
  export APP_GROUP_ID=$(mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.groupId | grep -v '\[')
  export APP_NAME=$(mvn -o org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.artifactId | grep -v '\[')
  export APP_VERSION=$(mvn -o org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version | grep -v '\[')

  echo "APP_GROUP_ID="$APP_GROUP_ID
  echo "APP_NAME="$APP_NAME
  echo "APP_VERSION="$APP_VERSION

  # Set docker env params
  ## Docker app jar is the generated app
  export APP_JAR=target/$APP_NAME-$APP_VERSION.jar
  echo "APP_JAR="$APP_JAR

  ## Docker image repo maps to group id from maven pom
  ## Docker app name maps to artifact id from pom
  ## Docker image version maps to app version in pom
  export APP_BASE_DOCKER_TAG=$APP_GROUP_ID/$APP_NAME:$APP_VERSION

  echo "APP_BASE_DOCKER_TAG="$APP_BASE_DOCKER_TAG

  export APP_DCK_REPO_TAG=$SHP_DCR_REGISTRY/$APP_BASE_DOCKER_TAG
  echo "APP_DCK_REPO_TAG="$APP_DCK_REPO_TAG

  BASE_CONFIG=$SHP_HOME/service-platform-operations/$SHP_TEAM_NAME/$APP_NAME/app-config.sh
  ENV_CONFIG=$SHP_HOME/service-platform-operations/$SHP_TEAM_NAME/$APP_NAME/app-config-$SHP_TARGET_ENV.sh

  # this line will display an alert if not app specific configs are defined - this is NOT an error
  source $BASE_CONFIG
  source $ENV_CONFIG

  if [ "$instance_count" ] ;
  then
    export APP_INST_CNT=$instance_count
  fi

}


build_microservice_pkg() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 6 Build and Package Application"
  printf '\n********************************************************************************\n'

  # Build microservice
  # build app
  cd $APP_BASEFLDR
  mvn install

  # test app
  ## run app in first console
  #java -jar ./target/$SHP_ARTIFACT_ID-$SHP_MS_VERSION.jar

  ## execute in second console
  ###curl -X GET http://localhost:8080/hello
  ## terminate java process in first console
}

build_ms_docker_image() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 7 Build Application Docker Image and Push to Repo"
  printf '\n********************************************************************************\n'

  # Create docker image of the microservice
  # go to microservice base folder - build folder
  cd $APP_BASEFLDR

  # set docker env. to use minikube
  ## will mean that all docker commands will run effectively inside minikube
  # eval $(minikube docker-env)

  printf "7.1 Starting creation of Docker Image for - "$APP_BASEFLDR/$APP_JAR"\n"
  # Create docker image of the application - use the standard java app docker file provided
  docker build -f $SHP_HOME/service-platform-toolkit/utils/docker/app-images/JavaAppDockerfile -t $APP_BASE_DOCKER_TAG --build-arg JAR_FILE=$APP_JAR $APP_BASEFLDR

  printf "\n7.2 Docker image created - "$APP_BASE_DOCKER_TAG"\n"

  # test app

  ## run in first console
  # docker run -p 8080:8080 $APP_REPO/$APP_NAME:$APP_VERSION

  # run in a different console
  # minikube ssh
  # test url for hello-world app - from inside minikube
  # curl -X GET http://localhost:8080/hello

  # terminate docker run process

  # tag and push the image to the docker registry
  printf "\n7.3 Uploading docker image to Docker Repository - "$APP_DCK_REPO_TAG"\n"
  docker tag $APP_BASE_DOCKER_TAG $APP_DCK_REPO_TAG
  docker push $APP_DCK_REPO_TAG
}

deploy_app_to_shp_k8s() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 8 Deploy application to Kubernetes cluster"
  printf '\n********************************************************************************\n'

  cd $APP_BASEFLDR
  mkdir $SHP_HOME/service-platform-operations/$SHP_TEAM_NAME/$APP_NAME

  BASE_DEPLOY_YAML=$SHP_HOME/service-platform-operations/base-yamls/microservice-deployment.yml
  BASE_SERVICE_YAML=$SHP_HOME/service-platform-operations/base-yamls/microservice-service.yml
  BASE_INGRESS_YAML=$SHP_HOME/service-platform-operations/base-yamls/microservice-ingress.yml

  APP_DEPLOY_YAML=$SHP_HOME/service-platform-operations/$SHP_TEAM_NAME/$APP_NAME/app-deployment-$SHP_TARGET_ENV.yml
  APP_SERVICE_YAML=$SHP_HOME/service-platform-operations/$SHP_TEAM_NAME/$APP_NAME/app-service-$SHP_TARGET_ENV.yml
  APP_INGRESS_YAML=$SHP_HOME/service-platform-operations/$SHP_TEAM_NAME/$APP_NAME/app-ingress-$SHP_TARGET_ENV.yml

  eval "echo \"$(< $BASE_DEPLOY_YAML)\"" > $APP_DEPLOY_YAML
  printf "\n8.1 - Application Deployment Config created - "$APP_DEPLOY_YAML

  eval "echo \"$(< $BASE_SERVICE_YAML)\"" > $APP_SERVICE_YAML
  printf "\n8.2 - Application Service Config created - "$APP_SERVICE_YAML

  eval "echo \"$(< $BASE_INGRESS_YAML)\"" > $APP_INGRESS_YAML
  printf "\n8.3 - Application Ingress Config created - "$APP_INGRESS_YAML

  # Deploy microservice to K8s cluster in the K8S_NAMESPACE
  printf "\n8.4 - Starting Deployment of Application to Kubernetes cluster\n"
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
# startup
set_app_env
load_team_platform_config
load_app_env_params
build_microservice_pkg
build_ms_docker_image
# deploy_app_to_shp_k8s
print_microservice_domain
