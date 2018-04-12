TBD - need to push shp to github

First-time Setup

1. Set initial env values

```
# Set the shp base folder  (~/sandbox/shp for me)
export SHP_HOME=~/sandbox/shp

# set docker registry env variable
export DOCKER_REGISTRY='localhost:5000'

```
2. Minikube setup

```
# run from SHP_HOME

cd $SHP_HOME

# start the minikube cluster
minikube start --insecure-registry localhost:5000

# set docker env. to use minikube
# will mean that all docker commands will run effectively inside minikube
eval $(minikube docker-env)

# setup the docker registry inside the minikube environment
docker run -d -p 5000:5000 --restart=always --name registry   -v /data/docker-registry:/var/lib/registry registry:2

# validate registry service is up and running
docker ps | grep registry

# list all containers and services in the kubernetes cluster
kubectl get pods,services --all-namespaces

# launch dashboard
minikube dashboard

# each platform instance will have a base domain - e.g. local.service.platform
# further each namespace will have it's own subdomain

# Setup DNS resolution to the minikube cluster
# Ensure that the dns nameserver is configured at /etc/resolver/<minikube base domain> - local.service.platform
MINIKUBE_IP=$(minikube ip) docker-compose -f $SHP_HOME/utils/kubernetes/dns.yml -p minikube-dns up -d

# Enable ingress in minikube
minikube addons enable ingress

# the subdomain for kube-system and other kubernetes system services will be system.<base domain> - system.local.service.platform - for me

# Enable Kubernetes Dashboard Ingress - both approaches shown for demo -
# Option 1 - dashboard gets a domain
kubectl apply -f $SHP_HOME/utils/kubernetes/dashboard-ingress-domain.yml
curl -X GET http://dashboard.system.local.service.platform
# Option 2 - dashboard is a route on the base domain for the platform instance
kubectl apply -f $SHP_HOME/utils/kubernetes/dashboard-ingress-path.yml
curl -X GET http://system.local.service.platform/dashboard

```

## refer ingress rewrite -
https://kubernetes.io/docs/concepts/services-networking/ingress/ &
https://github.com/kubernetes/ingress-nginx/blob/master/docs/examples/rewrite/README.md


3. TBD: Create the base docker image
--- base dockerfile - https://github.com/docker-library/openjdk/blob/master/8-jdk/alpine/Dockerfile

TBD - AppD agent
TBD - HSBC Certs
TBD - Splunk logging drivers

```

# build base image

export HSBC_BASE_REPO='hsbc-digital'
cd $SHP_HOME/utils/docker/base-images

docker build -f JavaBaseDockerfile -t $HSBC_BASE_REPO/shp-openjdk:8-jdk-alpine --build-arg APPD_AGENT=appd-dummy.jar --build-arg HSBC_CERT_KEYSTORE=hsbc-certs-dummy.jks --build-arg LOG_DRIVER='Splunk' .

# push image to docker repository
docker tag $HSBC_BASE_REPO/shp-openjdk:8-jdk-alpine $DOCKER_REGISTRY/$HSBC_BASE_REPO/shp-openjdk:8-jdk-alpine
docker push $DOCKER_REGISTRY/$HSBC_BASE_REPO/shp-openjdk:8-jdk-alpine


```
