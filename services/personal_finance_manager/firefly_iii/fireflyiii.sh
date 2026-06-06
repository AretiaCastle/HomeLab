#!/bin/bash

personal_finance_manager_deployment_docker(){
    # Fireflyiii
    sudo mkdir -p /mnt/docker_volumes/firefly_iii/upload
    sudo mkdir -p /mnt/docker_volumes/firefly_iii/db
    docker compose -p "${project_name}" -f firefly_iii/docker-compose.yml up -d
}
