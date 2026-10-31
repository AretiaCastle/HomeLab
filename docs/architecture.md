# Architecture

Every service is independent: it does not need any other service to be
deployed, nor to be on the same host. All of them can run on a single host or
be spread across several ones, each host deploying only its services from its
own clone of the repository.

## Networking

There is no docker network shared between services. Every service is an
independent docker compose stack that uses its own default network and
publishes on the host the ports it needs.

The ingress (Nginx Proxy Manager) routes the traffic to `<host IP>:<published
port>`, the same way whether the service is on the same host as the proxy or
on another one. Services can be deployed in any order and moved between hosts
by only updating their proxy host entry.

Containers of the same stack (e.g. Firefly III core, database and cron) reach
each other by service name through the stack default network.

## Published ports

Administration panels of the network services use the `10081-10100` range.
Applications start at `10101`.

| Service                        | Port         | Description                     |
| ------------------------------ | ------------ | ------------------------------- |
| Ingress                        | 80, 443      | HTTP / HTTPS traffic            |
| DNS                            | 53 tcp/udp   | DNS                             |
| VPN                            | 51820 udp    | WireGuard                       |
| DNS                            | 10081        | Pi-hole admin panel             |
| Ingress                        | 10083        | Nginx Proxy Manager admin panel |
| VPN                            | 10086        | WGDashboard                     |
| Personal Finance Manager (pfm) | 10101        | Firefly III                     |

Ports are configured in each `services/<service>/.env`.
