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

  export PATH=$PATH:$HOME/tools/hudson.tasks.Maven_MavenInstallation/maven/bin


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
  echo $(pwd)
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


create_config() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 5 Create Kubernetes Deployment Configuration"
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

}


# execute script

set_shp_env
set_app_env
load_team_platform_config
load_app_env_params
create_config
