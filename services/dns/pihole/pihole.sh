#!/bin/bash

pihole_baremetal_deployment(){
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

pihole_dokcer_deployment(){
    #PiHole
    docker_compose_deploy "pihole"

    # TODO: backup automation
}
