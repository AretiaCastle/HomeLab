# Public dynamic DNS Service

In order to access services hosted in a home lab from the internet, it is often
necessary to have a domain name that points to the public IP address of the home
network. This service provides a way to automatically update a DNS record with the
current public IP address of the home network, allowing users to access their
services using a consistent domain name.

## DuckDNS

- [Official Site](https://www.duckdns.org/)

### Deployment

#### Docker Compose

- [Deployment documentation](https://docs.linuxserver.io/images/docker-duckdns/)

Create the subdomain in the DuckDNS website and set it, together with the
account token, in `duckdns/.env.duckdns`.

```shell
make external_ddns
```

The container updates the subdomains with the public IP of the host network
every 5 minutes. It does not publish any port, so it can run on any host of the
network.

Check the updates in its logs:

```shell
make logs CONTAINER=duckdns
```

#### Bare-metal

- [Installation documentation](https://www.duckdns.org/install.jsp)

### Backup and restore

There is nothing to back up: the service has no persistent data and its
configuration is the `duckdns/.env.duckdns` file.

---
