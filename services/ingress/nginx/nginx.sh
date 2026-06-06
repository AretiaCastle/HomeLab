#!/bin/bash

ingress_deployment_docker(){
    # nginx Ingress
    sudo mkdir -p /mnt/docker_volumes/ingress/nginx/data
    sudo mkdir -p /mnt/docker_volumes/ingress/nginx/letsencrypt
    docker network create ingress
    docker compose -p "${project_name}" -f nginx/docker-compose.yml up -d
}
