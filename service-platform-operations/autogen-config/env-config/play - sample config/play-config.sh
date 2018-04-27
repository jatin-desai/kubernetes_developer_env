#!/usr/bin/env bash

declare container_port=8080
declare service_port=$container_port
declare shp_docker_registry="docker.registry.internal"
declare k8s_namespace=play
declare app_subdomain=play
