# VPN Service

WireGuard VPN managed from the WGDashboard web interface.

## WGDashboard

- [Official website](https://docs.wgdashboard.dev/)

### Deployment

#### Docker Compose

- [Deployment documentation](https://docs.wgdashboard.dev/install/Docker.html)

```shell
make vpn
```

The image includes WireGuard, so it does not need to be installed on the host.
The host kernel must provide the `wireguard` module (included since Linux 5.6).

| Host Ports                       | Container Ports | Description   |
| -------------------------------- | --------------- | ------------- |
| `WGDASHBOARD_WEB_INTERFACE_PORT` | 10086/tcp       | Web interface |
| `WGDASHBOARD_VPN_PORT`           | 51820/udp       | WireGuard     |

On first start the container generates the `wg0` interface with NAT for the
VPN clients, so they can reach the host network and internet through the
container. The web interface account, the DNS given to the clients and the
public endpoint are set in `wgdashboard/.env.wgdashboard`.

#### Bare-metal

- [Installation documentation](https://docs.wgdashboard.dev/install/)

### Network configuration

Steps outside the repository needed to reach the VPN from the internet.

#### 1. Fixed IP for the host

Reserve in the router DHCP (or configure statically) the LAN IP of the host
running the VPN, so the port forwarding below does not break when it changes.

#### 2. Check the public IP is reachable

Compare the WAN IP shown in the router with the one seen from the internet:

```shell
curl -s https://ifconfig.me
```

If they differ, or the router WAN IP is in `100.64.0.0/10`, the ISP is using
CGNAT and incoming connections never reach the router. Ask the ISP for a public
IP before continuing.

#### 3. Port forwarding

Create a port forwarding rule in the router:

| Field         | Value                                 |
| ------------- | ------------------------------------- |
| Protocol      | UDP                                   |
| External port | `WGDASHBOARD_VPN_PORT` (51820)        |
| Internal IP   | LAN IP of the VPN host                |
| Internal port | `WGDASHBOARD_VPN_PORT` (51820)        |

Only the WireGuard port is forwarded. The web interface must stay reachable
only from the LAN or through the VPN.

If the host has its own firewall, allow the same UDP port. Docker published
ports bypass `ufw`, but not every firewall.

#### 4. Public endpoint

The client configurations point to the public address of the network. As it
usually changes, use a domain kept up to date by the
[external DDNS service](../external_ddns/external_ddns.md) and set it as
`public_ip` in `wgdashboard/.env.wgdashboard`. It can also be changed later
from the WGDashboard settings (peers remote endpoint).

#### 5. VPN address range

Clients get addresses from the `wg0` range (`10.0.0.0/24` by default). It must
not overlap with the home network nor with the networks the clients usually
connect from, otherwise their traffic is not routed through the VPN.

No static routes are needed in the router: client traffic leaves the container
with NAT, so for the rest of the network it comes from the VPN host.

#### 6. DNS for the clients

Set `global_dns` in `wgdashboard/.env.wgdashboard` to the LAN IP of the
[DNS service](../dns/dns.md) host to block ads and resolve local names also
through the VPN. Use a public DNS if it is not deployed.

#### 7. Peers

Create a peer for each device from the web interface and import its
configuration file or QR code in the WireGuard client. In the peer
`AllowedIPs` choose:

- `0.0.0.0/0`: all the device traffic goes through the VPN.
- Home network range plus the VPN range (e.g. `192.168.1.0/24, 10.0.0.0/24`):
  only the traffic to the home network goes through the VPN.

#### 8. Verification

Connect a client from outside the home network (e.g. mobile data) and check
its latest handshake:

```shell
docker exec wgdashboard wg show
```

### Backup and restore

Cold copy of its volumes (WireGuard interfaces, peers and dashboard database).
See [backups](../../docs/backups.md).

```shell
make backup-vpn
make restore-vpn
```

### Update

```shell
docker compose pull wgdashboard
make vpn
```

### Password reset

- [Official instructions](https://docs.wgdashboard.dev/reset-wgdashboard-password.html)

### Web browser interfaces

- [WGDashboard](http://localhost:10086)

---
