# AGENTS.md

Guidelines for AI agents working on this repository. Read
[docs/architecture.md](docs/architecture.md) and
[docs/project-structure.md](docs/project-structure.md) before changing
services.

## Principles

- The repository must not be tied to a specific infrastructure. Do not add
  machine names, IPs, personal paths or assumptions about which services share
  a host.
- Services are independent: any of them can be deployed alone, in any order,
  on any host.

## Docker

- Do not use shared or `external` docker networks. Each stack uses its own
  default network and publishes on the host the ports it needs.
- Each tool runs as its own compose project named `$PROJECT-<tool>`, defined in
  its script as `<TOOL>_COMPOSE_PROJECT="${PROJECT}-<tool>"`.
- Containers of the same stack reach each other by service name.
- Persistent data uses named volumes bound to paths defined in the service
  `.env` (under `$DEPLOYMENTS_DOCKER_VOLUMES`).
- Keep the container port fixed in `ports` and make only the host port
  configurable (`"${X_WEB_INTERFACE_PORT}:<container port>"`).

## Ports

- Network services admin panels: `10081-10100`.
- Applications: from `10101` upwards.
- Check the table in [docs/architecture.md](docs/architecture.md) before
  assigning a port and update it afterwards.

## Services

- Layout: `services/<service>/<service>.sh` plus one folder per tool with its
  `<tool>.sh`, `docker-compose.yml` and optional `.env.<tool>`.
- Service scripts accept `deploy`, `stop`, `clean`, `backup` and `restore`,
  each one with its target in the `makefile`. A new service needs all five
  targets and an entry in `statics/help.txt`.
- Backups use [lib/backup.sh](lib/backup.sh): every docker tool implements
  backup and restore with `docker_volumes_backup` and `docker_restore`, plus
  an application export when it has one. See [docs/backups.md](docs/backups.md).
- Configuration goes in `services/<service>/.env.example`; container variables
  in `.env.<tool>.example`. Never commit real `.env` files.

## Documentation

- Written in English.
- `README.md` only describes the project and its general usage. Internal
  workings go in `docs/`, and each service is documented in
  `services/<service>/<service>.md`.
- Do not document obvious steps such as copying `.env.example` files.

## Verification

Do not deploy to check changes. Use:

```bash
bash -n services/<service>/<tool>/<tool>.sh
docker compose -p test --project-directory services/<service>/<tool> \
  -f services/<service>/<tool>/docker-compose.yml config -q
```

`docker compose config` needs the global and service environment loaded
(`.env` and `services/<service>/.env`, or their `.example` files).
