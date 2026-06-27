#!/bin/bash

personal_finance_manager_deploy_docker(){
    # FireflyIII
    sudo mkdir -p /mnt/docker_volumes/firefly_iii/upload
    sudo mkdir -p /mnt/docker_volumes/firefly_iii/db
    docker compose -p "${PROJECT}" -f firefly_iii/docker-compose.yml up -d

    
}

personal_finance_manager_stop_docker(){
    echo "TODO: implement Firefly III stop"
}

personal_finance_manager_clean_docker(){
    echo "TODO: implement Firefly III clean"
}
