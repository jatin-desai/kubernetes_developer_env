#!/usr/bin/env bash

declare container_port=8080
declare service_port=$container_port
declare shp_docker_registry="docker.registry.platform"
declare k8s_namespace=platform
declare app_subdomain=platform
