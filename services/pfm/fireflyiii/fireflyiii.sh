#!/bin/bash

FIREFLYIII_FOLDER="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
FIREFLYIII_ENV_FILE="$FIREFLYIII_FOLDER/.env.fireflyiii"
FIREFLYIII_DB_ENV_FILE="$FIREFLYIII_FOLDER/.db.env.fireflyiii"

check_fireflyiii_env_files(){
    local missing=false

    if [[ ! -f "$FIREFLYIII_ENV_FILE" ]]; then
        echo "ERROR: missing file $FIREFLYIII_ENV_FILE" >&2
        missing=true
    fi

    if [[ ! -f "$FIREFLYIII_DB_ENV_FILE" ]]; then
        echo "ERROR: missing file $FIREFLYIII_DB_ENV_FILE" >&2
        missing=true
    fi

    if [[ "$missing" == true ]]; then
        echo "Create them from templates:" >&2
        echo "  cp $FIREFLYIII_FOLDER/.env.fireflyiii.example $FIREFLYIII_ENV_FILE" >&2
        echo "  cp $FIREFLYIII_FOLDER/.db.env.fireflyiii.example $FIREFLYIII_DB_ENV_FILE" >&2
        return 1
    fi

    return 0
}

personal_finance_manager_deploy_docker(){
    check_fireflyiii_env_files || return 1

    # FireflyIII
    sudo mkdir -p "$FIREFLYIII_UPLOAD_PATH"
    sudo mkdir -p "$FIREFLYIII_DB_PATH"
    
    docker compose \
        -p "${PROJECT}" \
        --project-directory "$FIREFLYIII_FOLDER" \
        -f "$FIREFLYIII_FOLDER/docker-compose.yml" \
        up -d
}

personal_finance_manager_stop_docker(){
    echo "TODO: implement Firefly III stop"
}

personal_finance_manager_clean_docker(){
    echo "TODO: implement Firefly III clean"
}
