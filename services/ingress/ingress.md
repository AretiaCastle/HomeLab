# Ingress service

## Nginx

- [Official Site](https://nginxproxymanager.com/)

### Deployment

#### Docker Compose

- [Deployment documentation](https://nginxproxymanager.com/setup/)

```shell
make ingress
```

This setup produce this ports exposed:

| Host Ports  | Container Ports | Description             |
| ----------- | --------------- | ----------------------- |
| 80          | 80              | HTTP traffic            |
| 443         | 443             | HTTPS traffic           |
| 10083       | 81              | Administration Panel    |

The proxy does not share any docker network with the other services. It
forwards the traffic to the port each service publishes on its host, so the
services can live on a different machine than the ingress.

### Backup and restore

Cold copy of its volumes (configuration, database and certificates). See
[backups](../../docs/backups.md).

```shell
make backup-ingress
make restore-ingress
```

### Update

Backup and update to the image versions of the repository. See
[updates](../../docs/updates.md).

```shell
make update-ingress
```

### Proxy host configuration

Once your service is running and publishing its port on the host, you can
configure the routing rule through the web administration panel:

1. Access to the proxy hosts panel.

2. Create a new Proxy Host.

3. Configure the following fields in the Details tab:

    1. **Domain Name:** `yourdomain.com`.
    2. **Scheme:** HTTP/HTTPS (how nginx communicates with the container)
    3. **Forward Hostname / IP:** LAN IP of the machine running the service.
       Do not use `localhost`, inside the proxy container it points to the
       container itself.
    4. **Forward Port:** the port published on that host (e.g. `10101` for
       Firefly III).
    5. (Optional) Enable SSL with Let’s Encrypt in the SSL tab.

4. Save the configuration.

<img 
src="./docs_statics/service_config.png"
alt="Admin interface image"
width="350"
style="display: block; margin: 0 auto;"
/>

### Network configuration

By default the services are only reachable from the home network and through
the [VPN](../vpn/vpn.md). Exposing them to the internet is optional.

#### Internal access (default)

No router changes are needed: ports 80 and 443 are not forwarded.

Each proxy host domain must resolve to the LAN IP of the ingress host. Add a
local DNS record for each domain in the [DNS service](../dns/dns.md) (Pi-hole
local DNS records), e.g. `firefly.home.arpa` pointing to the ingress host.
`home.arpa` is the domain reserved for home networks.

The devices of the home network and the VPN clients (with `global_dns` pointing
to Pi-hole) resolve those domains and reach the services through the proxy.

#### Access from the internet (optional)

Every exposed service can be reached by anyone, so only expose those that need
it and keep the rest internal or behind the VPN.

1. **Fixed IP and public IP**: reserve the LAN IP of the ingress host in the
   router and check the ISP does not use CGNAT, as described in the
   [VPN network configuration](../vpn/vpn.md#network-configuration) (steps 1
   and 2).

2. **Port forwarding**: forward TCP ports 80 and 443 to the LAN IP of the
   ingress host. Never forward the administration panel (10083) nor the ports
   published by the services, all the traffic must go through the proxy.

    | Protocol | External port | Internal IP           | Internal port |
    | -------- | ------------- | --------------------- | ------------- |
    | TCP      | 80            | LAN IP of the ingress | 80            |
    | TCP      | 443           | LAN IP of the ingress | 443           |

3. **Public domain**: use the domain kept up to date by the
   [external DDNS service](../external_ddns/external_ddns.md). DuckDNS also
   resolves the subdomains of yours, so each service can have its own
   (e.g. `firefly.<your-subdomain>.duckdns.org`) with a single DDNS entry.

4. **Proxy host**: create a proxy host for the public domain as described
   above. To limit who can use it, add an Access List in Nginx Proxy Manager
   (allowed IPs or user and password) to the proxy host.

5. **Access from the home network**: to use the public domain also from home,
   add a Pi-hole local DNS record pointing it to the LAN IP of the ingress host.
   Otherwise it depends on the router supporting NAT loopback.

6. **Verification**: from outside the home network (e.g. mobile data) open
   `http://<public domain>`.

---
