#!/bin/bash

# Environment files functions. Requires ENV_FILE (global .env) and
# SERVICES_DIR.

# Print the variable names defined in an env file
# $1 Env file
env_keys(){
    grep -oE '^[[:space:]]*(export[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*=' "$1" \
        | sed -E 's/^[[:space:]]*(export[[:space:]]+)?//; s/=$//' \
        | sort -u
}

##
# Check that an env file exists and defines every variable of its template.
# $1 Env file
# $2 Template file (if it does not exist or has no variables there is nothing
#    to check)
# Returns 0 valid, 1 variables missing, 2 env file missing
##
env_check(){
    local env_file="$1"
    local template_file="$2"
    local missing_keys

    if [[ ! -f "$template_file" || -z "$(env_keys "$template_file")" ]]; then
        return 0
    fi

    if [[ ! -f "$env_file" ]]; then
        echo "ERROR: $env_file not found" >&2
        return 2
    fi

    missing_keys="$(comm -23 <(env_keys "$template_file") <(env_keys "$env_file"))"
    if [[ -n "$missing_keys" ]]; then
        echo "ERROR: variables of $(basename "$template_file") missing in $env_file:" >&2
        echo "$missing_keys" | sed 's/^/  /' >&2
        return 1
    fi
}

# Export the variables of the global .env and, if given, of a service .env
# $1 Service directory under services (optional)
env_load(){
    local service="$1"

    set -a
    # shellcheck source=/dev/null
    [[ -f "$ENV_FILE" ]] && source "$ENV_FILE"
    # shellcheck source=/dev/null
    [[ -n "$service" && -f "$SERVICES_DIR/$service/.env" ]] && source "$SERVICES_DIR/$service/.env"
    set +a
}
