#!/bin/bash

source "./wireguard/wireguard.sh"
wireguard_baremetal_deployment

source "./wgdashboard/wgdashboard.sh"
wgdashboard_baremetal_deployment
