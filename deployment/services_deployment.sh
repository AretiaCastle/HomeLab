#!/bin/bash

project_name="home_services"

# general
sudo mkdir -p /mnt/docker_volumes

# ingress
## nginx
sudo mkdir -p /mnt/docker_volumes/ingress/nginx/data
sudo mkdir -p /mnt/docker_volumes/ingress/nginx/letsencrypt
docker network create ingress
docker compose -p "${project_name}" -f nginx/docker-compose.yml up -d

# personal_finance_manager
## firefly_iii
sudo mkdir -p /mnt/docker_volumes/firefly_iii/upload
sudo mkdir -p /mnt/docker_volumes/firefly_iii/db
docker compose -p "${project_name}" -f firefly_iii/docker-compose.yml up -d

# torrent
## qBittorrent

## jackett

## sonarr

## radarr
