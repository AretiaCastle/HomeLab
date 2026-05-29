#!/bin/bash

# Constants
full_path_to_script="$(realpath "${BASH_SOURCE[0]}")"
BASE_FOLDER="$(dirname "$full_path_to_script")"
DEPLOYMENT_FOLDER="$BASE_FOLDER/deployments"
project_name="AretiaLab"

################################################################################

# Auxiliar functions
general_setup(){
    sudo mkdir -p "$USER/docker/volumes"
}

docker_compose_deploy(){
    software_name="$1"
    docker compose -p "${project_name}" -f "$DEPLOYMENT_FOLDER/$software_name/docker-compose.yml" up -d
}

check_commands_installed(){
    local requirements_file="$BASE_FOLDER/requirements.txt"
    local missing_commands=()
    local all_installed=true
    
    if [[ ! -f "$requirements_file" ]]; then
        echo "ERROR: requirements.txt not found at $requirements_file" >&2
        return 1
    fi
    
    while IFS= read -r cmd || [[ -n "$cmd" ]]; do
        # Skip empty lines and comments
        [[ -z "$cmd" || "$cmd" =~ ^[[:space:]]*# ]] && continue
        
        # Trim whitespace
        cmd=$(echo "$cmd" | xargs)
        
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
            all_installed=false
        fi
    done < "$requirements_file"
    
    if [[ "$all_installed" == false ]]; then
        echo "ERROR: The following required commands are not installed:" >&2
        printf '  - %s\n' "${missing_commands[@]}" >&2
        return 1
    fi
    
    return 0
}

################################################################################

# Deployment functions
dns_deployment_bare_metal(){
    # PiHole deployment - installation must run as root
    sudo bash -c 'curl -sSL https://install.pi-hole.net | bash'

    # Be careful to install with root but add the user who launches this script.
    sudo usermod -aG pihole "$USER"

    # Automated backup
    pihole_backup_folder_path="/home/$USER/devops/deployments/backups/pihole"
    mkdir -p "$pihole_backup_folder_path"

    # Backup every day at 03:30 and 04:00
    cron_file="/etc/crontab"
    cron_header="# Pihole DNS backup tasks"
    cron_pihole="30 03     * * *   root    cp -r /etc/pihole $pihole_backup_folder_path/pihole"
    cron_dnsmasq="00 04     * * *   root    cp -r /etc/dnsmasq.d $pihole_backup_folder_path/dnsmasq.d"

    if ! sudo grep -Fqx "$cron_header" "$cron_file"; then
        echo "$cron_header" | sudo tee -a "$cron_file" > /dev/null
    fi
    if ! sudo grep -Fqx "$cron_pihole" "$cron_file"; then
        echo "$cron_pihole" | sudo tee -a "$cron_file" > /dev/null
    fi
    if ! sudo grep -Fqx "$cron_dnsmasq" "$cron_file"; then
        echo "$cron_dnsmasq" | sudo tee -a "$cron_file" > /dev/null
    fi
}

dns_deployment_docker(){
    #PiHole
    docker_compose_deploy "pihole"

    # TODO: backup automation
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
