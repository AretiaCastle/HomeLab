#!/bin/bash

torrent_deploy(){
    ## qBittorrent

    ## jackett

    ## sonarr

    ## radarr
    echo "TODO: Torrent service deployment"
}

torrent_stop(){
    echo "TODO: implement Torrent stop"
}

torrent_clean(){
    echo "TODO: implement Torrent clean"
}

torrent_backup(){
    echo "TODO: implement Torrent backup"
}

torrent_restore(){
    echo "TODO: implement Torrent restore"
}

action="${1:-deploy}"

case "$action" in
    deploy)
        torrent_deploy
        ;;
    stop)
        torrent_stop
        ;;
    clean)
        torrent_clean
        ;;
    backup)
        torrent_backup
        ;;
    restore)
        torrent_restore
        ;;
    *)
        echo "Usage: $0 [deploy|stop|clean|backup|restore]" >&2
        exit 1
        ;;
esac
