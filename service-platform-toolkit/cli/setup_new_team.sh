#!/usr/bin/env bash


set_env() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 1 Setting working env"
  printf '\n********************************************************************************\n'

  export SHP_HOME=$(pushd $(dirname $0)/../.. >/dev/null ; echo ${PWD})
  echo "SHP home: ${SHP_HOME}"

  printf '\n\n********************************************************************************\n'
  printf " Stage 1 COMPLETE "
  printf '\n********************************************************************************\n'

}


collect_config() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 2 Collecting XFT / Product Line configuration"
  printf '\n********************************************************************************\n'

  # Get the XFT / Product team Namespace (e.g. Platform)

  printf "\n2.1 Define the XFT / Product team Namespace"

  printf '\nSpecify kubernetes namespace for the team - default is play: '; read nmsp ;
  if [ -z "$nmsp" ];
  then
    K8S_NAMESPACE='play'
  else
    K8S_NAMESPACE=$nmsp
  fi

  SUB_DOMAIN=$K8S_NAMESPACE

  printf '\n\n********************************************************************************\n'
  printf "Stage 2 COMPLETE"
  printf '\n********************************************************************************\n'

}


create_team_config() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 3 Creating ops configuration for - " $K8S_NAMESPACE
  printf '\n********************************************************************************\n'

  mkdir $SHP_HOME/service-platform-operations/autogen-config/env-config/$K8S_NAMESPACE
  mkdir $SHP_HOME/service-platform-operations/autogen-config/kube-yamls/$K8S_NAMESPACE

  printf "\n3.1 Creating base ops configuration - "$K8S_NAMESPACE"-config.sh\n"

  CONFIG_TEMPLATE=$SHP_HOME/service-platform-operations/base-config/env-config/config-template.sh
  TEAM_CONFIG=$SHP_HOME/service-platform-operations/autogen-config/env-config/$K8S_NAMESPACE/$K8S_NAMESPACE-config.sh

  cp $CONFIG_TEMPLATE $TEAM_CONFIG
  echo "declare k8s_namespace="$K8S_NAMESPACE >> $TEAM_CONFIG
  echo "declare app_subdomain="$SUB_DOMAIN >> $TEAM_CONFIG
  chmod +x $TEAM_CONFIG

  for targetenv in "local" "dev" "prod"
  do
    printf "\n3.2 Creating env ops configuration - "$K8S_NAMESPACE"-config-"$targetenv".sh\n"
    CONFIG_TEMPLATE=$SHP_HOME/service-platform-operations/base-config/env-config/config-template-$targetenv.sh
    TEAM_CONFIG=$SHP_HOME/service-platform-operations/autogen-config/env-config/$K8S_NAMESPACE/$K8S_NAMESPACE-config-$targetenv.sh
    cp $CONFIG_TEMPLATE $TEAM_CONFIG
    chmod +x $TEAM_CONFIG
  done

  printf "3.3 Configuration files created\n"
  cd $SHP_HOME/service-platform-operations/autogen-config/env-config/$K8S_NAMESPACE
  printf "\nConfig Location: "
  pwd
  printf "\nConfig files created: "
  ls

  printf '\n\n********************************************************************************\n'
  printf "Stage 3 COMPLETE"
  printf '\n********************************************************************************\n'

}


# create XFT Kubernetes namespace
create_k8s_namespace() {

  printf '\n\n********************************************************************************\n'
  printf "Stage 4 Creating Kubernetes namespace - " $K8S_NAMESPACE
  printf '\n********************************************************************************\n'

  # Create the XFT / Product team Namespace (e.g. play)
  kubectl create namespace $K8S_NAMESPACE

  printf '\n\n********************************************************************************\n'
  printf "Stage 4 COMPLETE"
  printf '\n********************************************************************************\n'

}




set_env
collect_config
create_team_config
create_k8s_namespace
