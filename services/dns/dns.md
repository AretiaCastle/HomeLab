# DNS Service

This DNS service uses Pi-hole as the DNS server to block ads and trackers at the
network level.

## Pi-hole

- [Official Site](https://pi-hole.net)
- [Official metal installation documentation](https://docs.pi-hole.net/main/basic-install/)
- [Official Docker installation documentation](https://github.com/pi-hole/docker-pi-hole)

### Deployment

#### Docker Compose

- [Deployment documentation](https://docs.pi-hole.net/docker/)

```shell
make dns
```

Ports 80 and 443 are left to the ingress service, the web interface is
published on `PIHOLE_WEB_INTERFACE_PORT`.

Port 53 must be free on the host. On systems with `systemd-resolved` disable
its stub listener first:

```shell
sudo sed -r -i.orig 's/#?DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf
sudo sh -c 'rm /etc/resolv.conf && ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf'
sudo systemctl restart systemd-resolved
```

#### Bare-metal

```shell
curl -sSL https://install.pi-hole.net | bash
sudo usermod -aG pihole "$USER"
```

### Backup and restore

#### Docker Compose

Backups use Pi-hole Teleporter, which exports the configuration, lists,
groups, clients and DHCP leases. The query log database is not included.

```shell
make backup-dns    # Creates $PIHOLE_BACKUP_PATH/<YYYYMMDD>.zip and its checksum
make restore-dns   # Imports the newest backup and restarts the container
```

### Update

#### Docker Compose

```shell
docker compose pull pihole
make dns
```

#### Bare-metal

```shell
pihole -up
```

### Web browser interfaces

- [Pi-hole](http://localhost:10081/admin)

---
