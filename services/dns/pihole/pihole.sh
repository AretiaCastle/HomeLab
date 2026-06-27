#!/bin/bash

pihole_baremetal_deployment(){
    # PiHole deployment - installation must run as root
    sudo bash -c 'curl -sSL https://install.pi-hole.net | bash'

    # Be careful to install with root but add the user who launches this script.
    sudo usermod -aG pihole "$USER"

    # Automated backup
    mkdir -p "$PIHOLE_BACKUP_PATH"

    # Backup every day at 03:30 and 04:00
    CRON_FILEPATH="/etc/crontab"
    cron_header="# Pihole DNS backup tasks"
    cron_pihole="30 03     * * *   root    cp -r /etc/pihole $PIHOLE_BACKUP_PATH/pihole"
    cron_dnsmasq="00 04     * * *   root    cp -r /etc/dnsmasq.d $PIHOLE_BACKUP_PATH/dnsmasq.d"

    if ! sudo grep -Fqx "$cron_header" "$CRON_FILEPATH"; then
        echo "$cron_header" | sudo tee -a "$CRON_FILEPATH" > /dev/null
    fi
    if ! sudo grep -Fqx "$cron_pihole" "$CRON_FILEPATH"; then
        echo "$cron_pihole" | sudo tee -a "$CRON_FILEPATH" > /dev/null
    fi
    if ! sudo grep -Fqx "$cron_dnsmasq" "$CRON_FILEPATH"; then
        echo "$cron_dnsmasq" | sudo tee -a "$CRON_FILEPATH" > /dev/null
    fi
}

# TODO: Deployment of Pihole with Docker
pihole_docker_deployment(){
    echo "TODO: implement Pihole docker deployment"
}

pihole_stop(){
    echo "TODO: implement Pihole stop"
}

pihole_clean(){
    echo "TODO: implement Pihole clean"
}
