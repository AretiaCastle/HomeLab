# Ingress service

## Nginx

- [Official Site](https://nginxproxymanager.com/)

### Deployment

#### Docker Compose

- [Deployment documentation](https://nginxproxymanager.com/setup/)

The deployment with docker compose and this configuration creates a network
named `nginx_network`. This network must be in all the other services that
are deployed with docker and need their traffic to be routed through the proxy.
If a container it is not in this network, that service could not work with the
`nginx` deployed.

In order to list the names of the networks you could use:

```shell
docker network ls
```

```yml
services:
  nginx-proxy-manager:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '80:80'
      - '443:443'
      - '10081:81'
    volumes:
      - data:/data
      - letsencrypt:/etc/letsencrypt
    networks:
      - nginx_network  

volumes:
  data_backup:
    driver: local
      driver_opts:
        type: none
        o: bind
        device: /mnt/docker_volumes/ingress/data
  letsencrypt_backup:
    driver: local
      driver_opts:
        type: none
        o: bind
        device: /mnt/docker_volumes/ingress/letsencrypt

networks:
  nginx_network:
    driver: bridge
```

```shell
sudo mkdir -p /mnt/docker/ingress/data
sudo mkdir -p /mnt/docker/ingress/letsencrypt
```

This setup produce this ports exposed:

| Host Ports  | Container Ports | Description             |
| ----------- | --------------- | ----------------------- |
| 80          | 80              | HTTP traffic            |
| 443         | 443             | HTTPS traffic           |
| 10081       | 81              | Administration Panel    |

### Proxy host configuration

Once your service container named like `youservice` is running, you can
configure the routing rule through the web administration panel:

1. Access to the proxy hosts panel.

2. Create a new Proxy Host.

3. Configure the following fields in the Details tab:

    1. **Domain Name:** `yourdomain.com`.
    2. **Scheme:** HTTP/HTTPS (how nginx communicates with the container)
    3. **Forward Hostname / IP:** `yourservice` (the name of the container within the Docker network).
    4. **Forward Port:** 80 (the internal port that the container exposes).
    5. (Optional) Enable SSL with Let’s Encrypt in the SSL tab.

4. Save the configuration.

<img 
src="./statics/service_config.png"
alt="Admin interface image"
width="350"
style="display: block; margin: 0 auto;"
/>
