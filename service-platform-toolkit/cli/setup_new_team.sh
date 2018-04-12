#!/usr/bin/env bash


set_env() {
  printf "Stage 1 Setting working env\n"
  export SHP_HOME=$(pwd)
}

startup() {
  printf "\nStage 2 Starting minikube cluster\n"
  source $SHP_HOME/service-platform-toolkit/cli/startup_local.sh
}

collect_config() {

  printf "\nStage 3 Collecting XFT / Product Line configuration\n"

  # Get the XFT / Product team Namespace (e.g. Platform)

  # Note : The subdomain should be based on the namespace - so it will be tech.local.service.platform
  # - it should be a one-to-one mapping
  # TBC - should the namespace and the subdomain name be the same ?
  printf "\n1.4 Define the XFT / Product team Namespace"
  printf "\nThere should ideally be a one-to-one mapping between the namespace and domain."
  printf "\nIf teams want them to be different, it can be configured in the product line config\n"

  printf '\nSpecify kubernetes namespace for the team - default is play: '; read nmsp ;
  if [ -z "$nmsp" ];
  then
    K8S_NAMESPACE='play'
  else
    K8S_NAMESPACE=$nmsp
  fi

  printf '\nSpecify kubernetes sub-domain for the team - default is '$K8S_NAMESPACE' : '; read dmn ;
  if [ -z "$dmn" ];
  then
    SUB_DOMAIN=$K8S_NAMESPACE
  else
    SUB_DOMAIN=$dmn
  fi

}

# create XFT Kubernetes namespace
create_k8s_namespace() {
  # Create the XFT / Product team Namespace (e.g. Platform)
  printf "\nStage 5 Creating Kubernetes namespace\n"
  kubectl create namespace $K8S_NAMESPACE
}

create_team_config() {

  printf "\nStage 4 Creating ops configuration for "$K8S_NAMESPACE"\n"
  mkdir $SHP_HOME/service-platform-operations/autogen-config/$K8S_NAMESPACE

  CONFIG_TEMPLATE=$SHP_HOME/service-platform-operations/base-config/env-config/config-template.sh
  TEAM_CONFIG=$SHP_HOME/service-platform-operations/autogen-config/$K8S_NAMESPACE/$K8S_NAMESPACE-config.sh

  cp $CONFIG_TEMPLATE $TEAM_CONFIG
  echo "declare k8s_namespace="$K8S_NAMESPACE >> $TEAM_CONFIG
  echo "declare app_subdomain="$SUB_DOMAIN >> $TEAM_CONFIG
  chmod +x $TEAM_CONFIG

  for targetenv in "local" "dev" "prod"
  do
    CONFIG_TEMPLATE=$SHP_HOME/service-platform-operations/base-config/env-config/config-template-$targetenv.sh
    TEAM_CONFIG=$SHP_HOME/service-platform-operations/autogen-config/$K8S_NAMESPACE/$K8S_NAMESPACE-config-$targetenv.sh
    cp $CONFIG_TEMPLATE $TEAM_CONFIG
    chmod +x $TEAM_CONFIG
  done
}

set_env
collect_config
create_team_config
create_k8s_namespace
