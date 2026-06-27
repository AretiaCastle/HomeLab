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
    *)
        echo "Usage: $0 [deploy|stop|clean]" >&2
        exit 1
        ;;
esac
