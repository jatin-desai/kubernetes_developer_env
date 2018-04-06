# Work done

## Local Desktop setup scripts created
 - creates the k8s cluster
 - creates a local docker registry
 - creates a dns server

### DEMO :
  - Quick overview of
```shell
./service-platform-toolkit/cli/setup_local.sh
```

### Next steps :
  - Move to CaSS
  - Support for Windows



## Mapping for PCF concepts to Kubernetes
  - PCF Org - Kubernetes Namespace
  - PCF Space - Environment Target (kept simple for now - local, dev, prod - expect them to evolve)
  - PCF Domain - Kubernetes Cluster domain
  ### Additional capabilities:
    - support for sub-domains - refer next point


## Mapping XFT constructs to Kubernetes
  - Each XFT / Product line gets its own namespace
  - Each Product line gets its own sub-domain
    - default config - maps it to the same value as the namespace, can be customized

## Scripting of the productline / team setup
  - automation of the necessary namespace (pcf-org) level configuration
### DEMO :
```shell  
   ./service-platform-toolkit/cli/setup_new_team.sh
```
### Next Steps :
    - Migrate to Jenkins

## Docker image creation / packaging against base images
  - sample base image created (with dummy appd agents and hsbc certs)
  - applications use the customized base image for creation of app docker images
### DEMO :
    - Refer to files
```shell
./service-platform-toolkit/docker/base-image/JavaBaseDockerfile
./service-platform-toolkit/docker/app-image/JavaAppDockerfile
```
### Next Steps :
    - Move to using the base image created by AWS team

## Scripting of Application packaging / deployment to kubernetes cluster
  - only root folder of the application needs to be specified
  - all configuration loaded / processed from pom and team config
  - provides support for overriding default config via externalized configuration
  - Kubernetes ops config files auto-generated
  - application build, packaged and deployed to kubernetes cluster
  - dns route exposed for application
  DEMO :
    - ./service-platform-toolkit/cli/microservice.sh
  Next Steps :
    - Migrate to Jenkins

## Application Logging incorporated platform meta-data as a part of the logs

----- e.g. ------
 2018-03-22 13:07:27.592 INFO 1 --- [nio-8080-exec-1] [K8S_Namespace=platform] [ENV_STAGE=local] [WORKER_NODE=minikube/192.168.99.100] [APP_NAME=platform-example-spring] [POD_INSTANCE=POD_INSTANCE_NAME_IS_UNDEFINED] [POD_IP=172.17.0.9] [SessionId=] com.hsbc.digital.platform.HelloWorld : Syslog output from Hello-world application

 2018-03-22 13:08:33.860 INFO 1 --- [nio-8080-exec-1] [K8S_Namespace=platform] [ENV_STAGE=local] [WORKER_NODE=minikube/192.168.99.100] [APP_NAME=platform-example-spring] [POD_INSTANCE=POD_INSTANCE_NAME_IS_UNDEFINED] [POD_IP=172.17.0.10] [SessionId=] com.hsbc.digital.platform.HelloWorld : Syslog output from Hello-world application

### DEMO :
    - get pod name kubectl get pods -n=platform
    - stream pod logs kubectl logs -f platform-example-spring-<> -n=platform
    - hit app endpoint - http://platform-example-spring.platform.local.service.platform/hello
    - see env. metadata in logs

### Next Steps :
    - stream to splunk




# Big Ticket Items / Next Steps :

## Automation
  - migration from shell scripts to Jenkins pipelines

## Central Docker Registry
  - for use in dev activities

## Logging
  - mechanism to stream logs from k8s to splunk
  - no out-of-box solution available
  - potential approach - use node-based looging with fluentd to stream to Splunk
  - discussion with Rob on logging approach

## Monitoring
  - monitoring with AppD
  - had an initial discussion with Melvin
  - to align to the current PCf approach of jvm monitoring (packaging of appd agent in base docker image)
  - need a follow-up with Melvin/Fred to get appd packages

## Security
  - adding e2e trust support
  - adding hsbc root certs

## Mule
  - adding support for mule apps
  - need to work with Mulesoft to understand mule buildpack components
  - need to agree on approach - mule as a part of app packaging or base image packaging - with impacts from migration perspective

## API Gateway
  - exposing the app via mule API gateway
  - configuring api raml to point the the new domain route of the app and then put to API gateway
  - support for gateway identifiers (for on-prem)
