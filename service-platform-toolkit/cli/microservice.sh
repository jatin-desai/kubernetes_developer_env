#!/usr/bin/env bash

### Usage ./service-platform-toolkit/cli/microservice.sh from the SHP home folder
# e.g. ./service-platform-toolkit/cli/microservice.sh

set_shp_env() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 1 Setting System Env"
  printf '\n********************************************************************************\n'
  ## run this from the SHP base folder (~/sandbox/shp/gitrepo for me)
  # Set the shp base folder
  export SHP_HOME=$(pwd)

  printf "\n Is this a dry run : default=n "; read dryrun

  if [[ $dryrun == "y" ]]; then
    DOCKER_CMD="echo docker"
    KUBECTL_CMD="echo kubectl"
  else
    DOCKER_CMD="docker"
    KUBECTL_CMD="kubectl"
  fi

  printf "\n Do you want to configure cntlm proxy - (y/n) (default - y): ";read proxyflag
  if [[ $proxyflag != "n" ]]; then
    USE_PROXY="y"
  else
    USE_PROXY="n"
  fi

  # the node ip used by docker within minikube to talk back to the host
  # configured as a part of the dns config - this is configured by VirtualBox
  SHP_NODE_IP='192.168.99.1'

  # change to this of using hyperkit
  # SHP_NODE_IP='192.168.64.1'


  SHP_PROXY_URL=http://$SHP_NODE_IP:3128

  if [[ $USE_PROXY == "y" ]]; then
    export http_proxy=$SHP_PROXY_URL
    export https_proxy=$SHP_PROXY_URL
    export HTTP_PROXY=$SHP_PROXY_URL
    export HTTPS_PROXY=$SHP_PROXY_URL
  fi

  printf '\n********************************************************************************\n'
  printf "Stage 1 Complete"
  printf '\n********************************************************************************\n\n'

}


set_app_env() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 2 - Collecting Application-specific configuration"
  printf '\n********************************************************************************\n'

  printf "\n2.1 Setting the Service Hosting Platform Environment Configuration\n"

  # configure the team name - which will determine the base configuration details - <team_name>-config.sh
  printf '\nSpecify the Namespace used for config - (default-play) : '
  read teamname
  if [ -z "$teamname" ];
  then
    printf "\nteamname env not provided - using play \n"
    export SHP_TEAM_NAME='play'
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
  printf "\n2.2 Select Microservice Project to Deploy\n"
  printf '\nSpecify the microservice application pom folder name : (default-platform-example-spring)'
  read appfldr
  if [ -z "$appfldr" ];
  then
    printf "\nfolder name not provided - using platform-example-spring \n"
    export APP_BASEFLDR=$SHP_HOME'/platform-example-spring'
  else
    export APP_BASEFLDR=$SHP_HOME'/'$appfldr
  fi

  printf '\n********************************************************************************\n'
  printf "Stage 2 Complete"
  printf '\n********************************************************************************\n\n'

}

load_team_base_config() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 3 Load Base Team Configuration for "$SHP_TEAM_NAME
  printf '\n********************************************************************************\n'

  export BASE_CONFIG=$SHP_HOME/service-platform-operations/autogen-config/env-config/$SHP_TEAM_NAME/$SHP_TEAM_NAME-config.sh
  export ENV_CONFIG=$SHP_HOME/service-platform-operations/autogen-config/env-config/$SHP_TEAM_NAME/$SHP_TEAM_NAME-config-$SHP_TARGET_ENV.sh

  source $BASE_CONFIG
  source $ENV_CONFIG

  export PLATFORM_BASE_DOMAIN=$shp_base_domain
  export SHP_DCR_REGISTRY=$shp_docker_registry
  export APP_NAMESPACE=$k8s_namespace

  export APP_SUBDOMAIN=$app_subdomain
  export APP_CONT_PORT=$container_port
  export APP_SVC_PORT=$service_port
  export APP_INST_CNT=$instance_count


  printf '\n********************************************************************************\n'
  printf "Stage 3 Complete"
  printf '\n********************************************************************************\n\n'


}

load_app_env_params() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 4 Load Application Environment Configuration "$APP_BASEFLDR
  printf '\n********************************************************************************\n'


  cd $APP_BASEFLDR

  printf "\n4.1 Loading microservice GroupId, Name and Version from application pom\n"
  export APP_GROUP_ID=$(mvn -o org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.groupId | grep -v '\[')
  export APP_NAME=$(mvn -o org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.artifactId | grep -v '\[')
  export APP_VERSION=$(mvn -o org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version | grep -v '\[')

  printf "\n Application Group Id : "$APP_GROUP_ID
  printf "\n Application Name     : "$APP_NAME
  printf "\n Application Version  : "$APP_VERSION

  # Set docker env params
  ## Docker app jar is the generated app
  export APP_JAR=target/$APP_NAME-$APP_VERSION.jar

  ## Docker image repo maps to group id from maven pom
  ## Docker app name maps to artifact id from pom
  ## Docker image version maps to app version in pom
  export APP_BASE_DOCKER_TAG=$APP_GROUP_ID/$APP_NAME:$APP_VERSION
  export APP_DCK_REPO_TAG=$SHP_DCR_REGISTRY/$APP_BASE_DOCKER_TAG

  printf "\n4.2 Load application-specific (optional) configuration\n"
  BASE_CONFIG=$SHP_HOME/service-platform-operations/user-config/$SHP_TEAM_NAME/$APP_NAME/app-config.sh
  ENV_CONFIG=$SHP_HOME/service-platform-operations/user-config/$SHP_TEAM_NAME/$APP_NAME/app-config-$SHP_TARGET_ENV.sh

  # this line will display an alert if not app specific configs are defined - this is NOT an error
  source $BASE_CONFIG
  source $ENV_CONFIG

  if [ "$instance_count" ] ;
  then
    export APP_INST_CNT=$instance_count
  fi

  if [ "$container_port" ] ;
  then
    export APP_CONT_PORT=$container_port
  fi

  if [ "$service_port" ] ;
  then
    export APP_SVC_PORT=$service_port
  fi

  printf '\n********************************************************************************\n'
  printf "Stage 4 Complete"
  printf '\n********************************************************************************\n\n'

}


build_microservice_pkg() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 5 Build and Package Application"
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
  printf '\n********************************************************************************\n'
  printf "Stage 5 Complete"
  printf '\n********************************************************************************\n\n'

}


build_ms_docker_image() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 6 Build Application Docker Image and Push to Registry"
  printf '\n********************************************************************************\n'

  # Create docker image of the microservice
  # go to microservice base folder - build folder
  cd $APP_BASEFLDR

  # set docker env. to use minikube
  eval $(minikube docker-env)

  ## will mean that all docker commands will run effectively inside minikube
  printf "6.1 Starting creation of Docker Image for - "$APP_BASEFLDR/$APP_JAR"\n"
  # Create docker image of the application - use the standard java app docker file provided
  $DOCKER_CMD build -f $SHP_HOME/service-platform-toolkit/docker-images/app-images/JavaAppDockerfile -t $APP_BASE_DOCKER_TAG --build-arg JAR_FILE=$APP_JAR $APP_BASEFLDR

  printf "\n6.2 Docker image created - "$APP_BASE_DOCKER_TAG"\n"

  # test app

  ## run in first console
  # docker run -p 8080:8080 $APP_REPO/$APP_NAME:$APP_VERSION

  # run in a different console
  # minikube ssh
  # test url for hello-world app - from inside minikube
  # curl -X GET http://localhost:8080/hello

  # terminate docker run process

  # tag and push the image to the docker registry
  printf "\n6.3 Uploading docker image to Docker Repository - "$APP_DCK_REPO_TAG"\n"
  $DOCKER_CMD tag $APP_BASE_DOCKER_TAG $APP_DCK_REPO_TAG
  $DOCKER_CMD push $APP_DCK_REPO_TAG
}

load_appdynamics_config() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 7 Load AppDynamics Configuration"
  printf '\n********************************************************************************\n'

  # load appdynamics configuration
  source $SHP_HOME/shp-hsbc-utils/appd/appd-config.sh
  export APPD_PROXY_HOST=$appd_proxy_host
  export APPD_PROXY_PORT=$appd_proxy_port
  export APPD_CONTROLLER_HOST=$appd_controller_host
  export APPD_CONTROLLER_PORT=$appd_controller_port
  export APPD_ACCOUNT_NAME=$appd_account_name
  export APPD_ACCESS_KEY=$appd_access_key
  export APPD_APP_NAME=$APP_NAME
  export APPD_TIER=$appd_tier
  export APPD_NODE_NAME=$appd_node_name"-"$SHP_NODE_IP"-"$SHP_TARGET_ENV

  printf "\nAPPD_PROXY_HOST :"$APPD_PROXY_HOST
  printf "\nAPPD_PROXY_PORT :"$APPD_PROXY_PORT
  printf "\nAPPD_CONTROLLER_HOST :"$APPD_CONTROLLER_HOST
  printf "\nAPPD_CONTROLLER_PORT :"$APPD_CONTROLLER_PORT
  printf "\nAPPD_ACCOUNT_NAME :"$APPD_ACCOUNT_NAME
  printf "\nAPPD_ACCESS_KEY :"$APPD_ACCESS_KEY
  printf "\nAPPD_APP_NAME :"$APPD_APP_NAME
  printf "\nAPPD_TIER :"$APPD_TIER
  printf "\nAPPD_NODE_NAME :"$APPD_NODE_NAME

  printf '\n\n********************************************************************************\n'
  printf "Stage 7 COMPLETE"
  printf '\n********************************************************************************\n'

}

generate_kube_config() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 8 Generate Kubernetes Deployment Configuration"
  printf '\n********************************************************************************\n'

  cd $APP_BASEFLDR
  mkdir $SHP_HOME/service-platform-operations/autogen-config/kube-yamls/$SHP_TEAM_NAME/$APP_NAME

  BASE_DEPLOY_YAML=$SHP_HOME/service-platform-operations/base-config/kube-yamls/microservice-deployment.yml
  BASE_SERVICE_YAML=$SHP_HOME/service-platform-operations/base-config/kube-yamls/microservice-service.yml
  BASE_INGRESS_YAML=$SHP_HOME/service-platform-operations/base-config/kube-yamls/microservice-ingress.yml

  APP_DEPLOY_YAML=$SHP_HOME/service-platform-operations/autogen-config/kube-yamls/$SHP_TEAM_NAME/$APP_NAME/app-deployment-$SHP_TARGET_ENV.yml
  APP_SERVICE_YAML=$SHP_HOME/service-platform-operations/autogen-config/kube-yamls/$SHP_TEAM_NAME/$APP_NAME/app-service-$SHP_TARGET_ENV.yml
  APP_INGRESS_YAML=$SHP_HOME/service-platform-operations/autogen-config/kube-yamls/$SHP_TEAM_NAME/$APP_NAME/app-ingress-$SHP_TARGET_ENV.yml

  eval "echo \"$(< $BASE_DEPLOY_YAML)\"" > $APP_DEPLOY_YAML
  printf "\n7.1 - Application Deployment Config created - "$APP_DEPLOY_YAML

  eval "echo \"$(< $BASE_SERVICE_YAML)\"" > $APP_SERVICE_YAML
  printf "\n7.2 - Application Service Config created - "$APP_SERVICE_YAML

  eval "echo \"$(< $BASE_INGRESS_YAML)\"" > $APP_INGRESS_YAML
  printf "\n7.3 - Application Ingress Config created - "$APP_INGRESS_YAML

  printf '\n\n********************************************************************************\n'
  printf "Stage 8 COMPLETE"
  printf '\n********************************************************************************\n'

}


deploy_app_to_shp_k8s() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 9 Deploy application to Kubernetes cluster"
  printf '\n********************************************************************************\n'

  # Deploy microservice to K8s cluster in the K8S_NAMESPACE
  printf "\n9.1 - Starting Deployment of Application to Kubernetes cluster\n"
  cd $SHP_HOME/service-platform-operations/autogen-config/kube-yamls/$SHP_TEAM_NAME/$APP_NAME
  $KUBECTL_CMD apply -f app-deployment-$SHP_TARGET_ENV.yml
  $KUBECTL_CMD apply -f app-service-$SHP_TARGET_ENV.yml
  $KUBECTL_CMD apply -f app-ingress-$SHP_TARGET_ENV.yml

  printf "\n9.2 Application Deployment Status\n"
  $KUBECTL_CMD get pods,services,ingress -n=$APP_NAMESPACE

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
load_team_base_config
load_app_env_params
build_microservice_pkg
build_ms_docker_image
load_appdynamics_config
generate_kube_config
deploy_app_to_shp_k8s
print_microservice_domain
