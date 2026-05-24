#!/bin/bash

# Constants
full_path_to_script="$(realpath "${BASH_SOURCE[0]}")"
DEPLOYMENT_FOLDER="$(dirname "$full_path_to_script")"
project_name="AretiaLab"

################################################################################

# Auxiliar functions
general_setup(){
    sudo mkdir -p "$USER/docker/volumes"
}

docker_compose_deploy(){
    software_name="$1"
    docker compose -p "${project_name}" -f "$DEPLOYMENT_FOLDER/$software_name/docker-compose.yml"/docker-compose.yml up -d
}

################################################################################

# Deployment functions
dns_deployment_bare_metal(){
    # PiHole deployment 
    curl -sSL https://install.pi-hole.net | bash
    sudo usermod -aG pihole "$USER"

    # Automated backup
    mkdir -p "$USER/backups/pihole"
    echo "30 03     * * *   root    cp -r /etc/pihole $USER/backups/pihole/pihole" | sudo tee -a /etc/crontab
    echo "00 04     * * *   root    cp -r /etc/dnsmasq.d /home/$USER/backups/pihole/dnsmasq.d" | sudo tee -a /etc/crontab
}

dns_deployment_docker(){
    #PiHole
    docker_compose_deploy "pihole"
}

# ingress
ingress_deployment_docker(){
    # nginx Ingress
    sudo mkdir -p /mnt/docker_volumes/ingress/nginx/data
    sudo mkdir -p /mnt/docker_volumes/ingress/nginx/letsencrypt
    docker network create ingress
    docker compose -p "${project_name}" -f nginx/docker-compose.yml up -d
}

personal_finance_manager_deployment_docker(){
    # Fireflyiii
    sudo mkdir -p /mnt/docker_volumes/firefly_iii/upload
    sudo mkdir -p /mnt/docker_volumes/firefly_iii/db
    docker compose -p "${project_name}" -f firefly_iii/docker-compose.yml up -d
}

torrent_deployment(){
    ## qBittorrent

    ## jackett

    ## sonarr

    ## radarr
    echo "TODO: Torrent service deployment"
}

################################################################################

# General Execution
