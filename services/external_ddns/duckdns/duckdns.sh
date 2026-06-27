#!/bin/bash

duck_dns_configuration(){
    # Validate required variables
    if [[ -z "$duckdns_domain" || -z "$duckdns_token" ]]; then
        echo "ERROR: duckdns_domain and duckdns_token must be set in .env file" >&2
        return 1
    fi
    
    duckdns_deployment_folder_path="$DEPLOYMENTS_BASE_PATH/duckdns"
    mkdir -p "$duckdns_deployment_folder_path"

    echo "echo url='https://www.duckdns.org/update?domains=$duckdns_domain&token=$duckdns_token&ip=' | curl -k -o $duckdns_deployment_folder_path/duck.log -K -" > "$duckdns_deployment_folder_path/duck.sh"
    chmod +x "$duckdns_deployment_folder_path/duck.sh"

    # Create cron task - update IP every 5 minutes
    CRON_FILEPATH="/etc/crontab"
    cron_header="# Duck DNS IP update"
    cron_task="*/5 *    * * *   $USER    $duckdns_deployment_folder_path/duck.sh >/dev/null 2>&1"

    if ! sudo grep -Fqx "$cron_header" "$CRON_FILEPATH"; then
        echo "$cron_header" | sudo tee -a "$CRON_FILEPATH" > /dev/null
    fi
    if ! sudo grep -Fqx "$cron_task" "$CRON_FILEPATH"; then
        echo "$cron_task" | sudo tee -a "$CRON_FILEPATH" > /dev/null
    fi
}

duck_dns_stop(){
    echo "TODO: implement DuckDNS stop"
}

duck_dns_clean(){
    echo "TODO: implement DuckDNS clean"
}
