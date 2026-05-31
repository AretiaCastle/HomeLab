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

load_env(){
    local env_file="$BASE_FOLDER/.env"
    
    if [[ ! -f "$env_file" ]]; then
        echo "WARNING: .env file not found at $env_file" >&2
        echo "Please copy .env.example to .env and fill in your secrets." >&2
        return 1
    fi
    
    # Load environment variables from .env file
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Export variables (format: KEY=VALUE)
        if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
            export "${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"
        fi
    done < "$env_file"
    
    echo "Environment variables loaded from $env_file"
    return 0
}

################################################################################

# ingress


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
load_env