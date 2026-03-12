# DNS Service

This DNS service uses Pi-hole as the DNS server to block ads and trackers at the
network level.

## Pi-hole

- [Official Site](https://pi-hole)
- [Official metal installation documentation](https://docs.pi-hole.net/main/basic-install/)
- [Official Docker installation documentation](https://github.com/pi-hole/docker-pi-hole)

One the service is ready you can access the admin interface at
`http://localhost/admin`

### Deployment

#### Bare-metal deployment

```shell
curl -sSL https://install.pi-hole.net | bash
sudo usermod -aG pihole $USER
```

#### Docker Compose deployment

The `docker-compose.yml` file in this directory contains a service definition.
Remenber to set the environment variables in a `.env` file.

```shell
docker compose up -d
```

### Update

#### Bare-metal update

```shell
pihole -up
```
