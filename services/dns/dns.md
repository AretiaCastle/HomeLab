# DNS Service

This DNS service uses Pi-hole as the DNS server to block ads and trackers at the
network level.

## Pi-hole

- [Official Site](https://pi-hole.net)
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

- [Installation documentation](https://docs.pi-hole.net/main/basic-install/)

### Backup and restore

Besides the cold copy of its volumes, the backup includes a Teleporter export
(configuration, lists, groups, clients and DHCP leases, without the query log).
See [backups](../../docs/backups.md).

```shell
make backup-dns
make restore-dns                              # Newest cold copy
make restore-dns BACKUP=export-<timestamp>.zip # Import a Teleporter export
```

### Update

Backup and update to the image versions of the repository. See
[updates](../../docs/updates.md).

```shell
make update-dns
```

### Web browser interfaces

- [Pi-hole](http://localhost:10081/admin)

---
