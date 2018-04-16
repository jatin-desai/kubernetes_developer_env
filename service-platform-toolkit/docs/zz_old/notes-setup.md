# Service Hosting Platform Projects

### service-platform-toolkit
  - This project contains all the  cli scripts and configuration for creating & deploying kube services
  - also contains reference configuration to use within SHP - e.g. logback config
  - These are only for the desktop env. and standard replacements for all these would need to be designed & implemented as a part of the SHP project


### service-platform-operations
  - similar to the digital-sandbox-operations project in TP
  - provides the base platform configuration - which is in the base-config sub-folder
  - all application-specific configuration is defined in the


### shp-hsbc-utils
  - this project contains hsbc-specific artifacts - appd configuration and certs
  - this has been externalized to enable the other projects to be hsbc-agnostic


### microservices projects
  - e.g. platform-example-spring - a sample spring-boot project developed as per the TP project standards


# Configuration Settings


## Setup desktop

* Configure cntlm proxy if not already setup
  * ensure that it is listening on port 3128


* Configure docker
  - add proxy - http://docker.for.mac.host.internal:3128
  - add insecure registry - docker.for.mac.host.internal:5000


## Command-line Configuration

* ```SHP_HOME``` - Base service hosting platform folder - contains all git projects
  * in my case this is ```$HOME/sandbox/shp/gitrepo/```
      - service-platform-toolkit
      - service-platform-operations
      - shp-hsbc-utils
      - platform-example-spring


* ```SHP_DOMAIN_NAME``` - the base domain name for the kubernetes cluster
  * in my case this is ```local.service.platform```
    - Note: while this is specified as a config. param - there are additional dependencies that also need to be changed
    - For initial dev. purposes, please keep this unchanged


* ```SHP_DOCKER_REGISTRY``` - the docker registry to be used by the kubernetes cluster for pulling service images for Deployment
  * in my case this points to a docker registry running locally
    - ```docker.for.mac.host.internal:5000```
    - note: docker.for.mac.host.internal is the hostname that docker uses to point to the registry on localhost (on macs)


*  ```SHP_PROXY_URL``` - Proxy Settings for Internet Access
  * using cntlm proxy running on localhost
  * used by docker and minikube to pull images from internet


### Service Deployment

* ```SHP_BASE_REPO``` - the tag for base docker images
  * in my case this is 'digital'
    - this is the repository tag under which all base docker images are created
    - e.g. digital/shp-openjdk:8-jdk-alpine


* ```SHP_TEAM_NAME```


* ```SHP_TARGET_ENV```


* ```APP_BASEFLDR```


## Env. Configuration for Kube Deployments (service-platform-operations)

### ```base-config``` items

* ```env-config``` folder
  * externalized configuration related to the kube target environment that is configurable
    - docker registry url - ```shp_docker_registry```
    - default container and service ports - ```container_port``` and ```service_port```
    - pod instance counts - ```instance_count```


* ```kube-yamls``` folder
  * base kubernetes yamls to create Deployments, Services and Ingress rules
    - ```microservice-deployment.yml```
    - ```microservice-service.yml```
    - ```microservice-ingress.yml```
  * all application specific information is merged into these files at deploy time to generate runtime configuration
    - runtime configuration stored in the ```autogen-config``` folder

### ```user-config``` items


### ```autogen-config``` items
