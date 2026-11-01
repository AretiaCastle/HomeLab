# AGENTS.md

Guidelines for AI agents working on this repository. Read
[docs/architecture.md](docs/architecture.md),
[docs/project-structure.md](docs/project-structure.md) and
[docs/backups.md](docs/backups.md) before changing services.

## Principles

- The repository must not be tied to a specific infrastructure. Do not add
  real machine names, IPs, personal paths or assumptions about which services
  share a host.
- Values in `.env*.example` files are examples that show the expected format
  (e.g. `BACKUP_REMOTE_HOST='nas.home'`). Keep them; do not replace them with
  real values nor empty them.
- Services are independent: any of them can be deployed alone, in any order,
  on any host.
- Everything is run through `make`. Scripts are not meant to be run directly.

## Docker

- Tools are deployed with Docker. Scripts do not install packages nor change
  the host (cron, sysctl, services...); bare-metal installation is only linked
  in the service documentation. The only host changes are the backups cron
  task and the directories of the volumes.
- Do not use shared or `external` docker networks. Each stack uses its own
  default network and publishes on the host the ports it needs.
- Each tool runs as its own compose project named `$PROJECT-<tool>`, defined in
  its script as `<TOOL>_COMPOSE_PROJECT="${PROJECT}-<tool>"`.
- Containers of the same stack reach each other by service name.
- Persistent data uses named volumes bound to paths under
  `$<TOOL>_BASE_VOLUMES_PATH` (inside `$DEPLOYMENTS_DOCKER_VOLUMES`), defined in
  the service `.env`.
- Keep the container port fixed in `ports` and make only the host port
  configurable (`"${X_WEB_INTERFACE_PORT}:<container port>"`).
- Files owned by other users (e.g. databases) are read or written from a helper
  container, not with `sudo`.
- Volume directories are created empty with `mkdir -p`, without `sudo`. On the
  first mount Docker copies into the empty volume the image directory with its
  owner, so containers that do not run as root can write on it.

## Ports

- Network services admin panels: `10081-10100`.
- Applications: from `10101` upwards.
- Check the table in [docs/architecture.md](docs/architecture.md) before
  assigning a port and update it afterwards.

## Services

- Layout: `services/<service>/<service>.sh` plus one folder per tool with its
  `<tool>.sh`, `docker-compose.yml` and optional `.env.<tool>`.
- Service scripts accept `deploy`, `stop`, `clean`, `backup` and `restore`
  and delegate them to functions of their tools (`<tool>_deploy_docker`,
  `<tool>_backup_docker`...).
- Adding the service to `SERVICES` in the `makefile` creates its targets. It
  also needs an entry in `statics/help.txt`, the services table of
  `README.md` and, if it publishes ports or has backups, the tables of
  `docs/architecture.md` and `docs/backups.md`.
- The `makefile` only defines targets: logic goes in
  [scripts/homelab.sh](scripts/homelab.sh), sourced libraries in `lib/` and
  executables called by make in `scripts/`.
- Scripts print errors to stderr and exit non-zero on failure: `make` stores
  their output in the execution log and reports the action as failed.

## Backups

- Use [lib/backup.sh](lib/backup.sh): every docker tool with persistent data
  implements backup and restore with `docker_volumes_backup` and
  `docker_restore`, plus an application export when it has one.
- Backups of tools that are not deployed are skipped
  (`docker_project_deployed`), so `backup-all` works on any host.
- Backup files follow `volumes-<timestamp>.tar.gz` and
  `export-<timestamp>.<ext>`, each one with its `.sha256`, and are pruned with
  `backup_prune`.

## Environment files

- Global settings go in `.env.example`, service settings in
  `services/<service>/.env.example` and container variables in
  `services/<service>/<tool>/.env.<tool>.example`. Never commit real `.env`
  files.
- Every variable of an `.env.example` is required in its `.env`
  ([lib/env.sh](lib/env.sh) checks it before each action). Adding a variable
  forces existing `.env` files to be updated, so mention it in the commit.
- Tools check that their container env file exists before deploying
  (`check_<tool>_env_files`).

## Security

- Never print secrets (passwords, tokens) nor pass them as command line
  arguments. Use environment variables instead (e.g. `MYSQL_PWD`).
- Only the ports that must be reachable from the internet (VPN, ingress) are
  meant to be forwarded in the router. Admin panels stay in the LAN or behind
  the VPN.

## Bash style

- `#!/bin/bash`, functions declared as `name(){`, 4 spaces indentation in
  libraries and tool scripts.
- Globals in `UPPER_SNAKE_CASE` prefixed by the tool (`PIHOLE_FOLDER`),
  function variables declared with `local` in `lower_snake_case`.
- Functions with parameters are documented with a `##` block listing `$1`,
  `$2`...
- Use `[[ ]]` and quote every variable expansion.

## Documentation

- Code, comments, documentation and commits are written in English.
- `README.md` only describes the project and its general usage. Internal
  workings go in `docs/`, and each service is documented in
  `services/<service>/<service>.md`.
- Service documentation sections: deployment (Docker Compose with its official
  documentation link, bare-metal only as a link), configuration outside the
  repository when needed (e.g. router), backup and restore, web interfaces.
- Do not document obvious steps such as copying `.env.example` files.

## Verification

Do not deploy real services to check changes. Use:

```bash
bash -n <script>
docker compose -p test --project-directory services/<service>/<tool> \
  -f services/<service>/<tool>/docker-compose.yml config -q
```

`docker compose config` needs the global and service environment loaded
(`.env` and `services/<service>/.env`, or their `.example` files).

To check `make` targets without touching the real configuration, logs or
data, point them to temporary files:

```bash
make <target> ENV_FILE=/tmp/test/global.env LOG_FILE=/tmp/test/run.log
```

If a real run is needed, use a throwaway `PROJECT`, volumes and backups paths
in a temporary directory and free host ports, and clean it afterwards.

## Commits

[Conventional Commits](https://www.conventionalcommits.org/):

```text
<type>(<optional scope>): <description>

<optional body>

<optional footer>
```

- Types: `feat`, `fix`, `refactor`, `docs`, `chore`.
- Scope: the service or area changed (`dns`, `vpn`, `backup`, `makefile`...).
- Description in lowercase, imperative mood and without final period.
- A commit can group several changes, each one in its own
  `<type>: <description>` line.
- Mark with `!` and a `BREAKING CHANGE:` footer the changes that require
  updating existing `.env` files or change make targets.
