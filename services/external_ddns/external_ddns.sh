#!/bin/bash

EXTERNAL_DDNS_SERVICE_FOLDER="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

source "$EXTERNAL_DDNS_SERVICE_FOLDER/duckdns/duckdns.sh"
duck_dns_configuration
