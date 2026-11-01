# Project structure

```text
HomeLab/
├── makefile              # Targets of every action
├── AGENTS.md             # Guidelines for AI agents (imported by CLAUDE.md)
├── requirements.txt      # Commands checked by `make check`
├── .env                  # Global configuration
├── logs/                 # Logs of every make execution
├── docs/                 # Internal documentation
├── lib/                  # Functions sourced by the scripts
│   ├── backup.sh         # Backup and restore of docker tools
│   ├── env.sh            # Env files check and load
│   └── log.sh            # Log messages and retention
├── scripts/              # Executables called by make
│   ├── homelab.sh        # Entry point of every make target
│   └── backup_remote.sh  # Backups copy to a remote host
├── statics/
│   └── help.txt          # Output of `make help`
└── services/
    └── <service>/
        ├── <service>.sh  # Service entry point
        ├── <service>.md  # Service documentation
        ├── .env          # Service configuration
        └── <tool>/       # One folder per tool (pihole, nginx, fireflyiii...)
            ├── <tool>.sh
            ├── docker-compose.yml
            └── .env.<tool>   # Container environment, when needed
```

## Environment files

Configuration is layered:

1. `.env` (required): shared values such as `PROJECT`, the base paths for
   volumes and backups, the backup settings and the logs retention.
2. `services/<service>/.env`: values of that service. It can use and override
   the global ones. Required when its `.env.example` defines variables.

`make` loads both files, in that order, before running the service script.

Before any action [lib/env.sh](../lib/env.sh) checks that each file
exists and defines every variable of its `.env.example`, listing the missing
ones. This also detects env files outdated after a template change. A service
without `.env` is considered not configured on the host: its backups are
skipped (so `backup-all` works on hosts running only some services) and any
other action fails.

Container specific variables live in `services/<service>/<tool>/.env.<tool>`
and are passed to the container through `env_file` in its compose file.

## Service scripts

Each `services/<service>/<service>.sh` receives one action:

| Action    | Make target              |
| --------- | ------------------------ |
| `deploy`  | `make <service>`         |
| `stop`    | `make stop-<service>`    |
| `clean`   | `make clean-<service>`   |
| `backup`  | `make backup-<service>`  |
| `restore` | `make restore-<service>` |

The service script sources the scripts of its tools and delegates each action
to them. Docker based tools run their own compose file as an independent
compose project named `$PROJECT-<tool>` (e.g. `homelab-pihole`), so stacks
never share containers or networks. `make status` lists the containers of
every project starting with `$PROJECT-`.

## Make targets

The `makefile` only defines the targets. Each one calls
[scripts/homelab.sh](../scripts/homelab.sh), which checks the env files, runs
the service script or the backup action and logs its result. The scripts are
not meant to be run without `make`.

## Logs

Each `make` execution writes a log file in `logs/` named
`<YYYYMMDD_HHMMSS>-<target>.log` (e.g. one file for all the services of
`backup-all`). It contains the start and result of each action and the output
of the scripts. Requirement checks only log errors.

Logs older than `LOG_RETENTION_DAYS` (global `.env`, 30 by default) are removed
on each execution.

## Adding a service

1. Create `services/<service>/` following the layout above.
2. Add the service to `SERVICES` in the `makefile`, which creates its five
   targets, and to `statics/help.txt`.
3. Publish the ports the service needs and do not attach it to external
   docker networks (see [architecture](architecture.md)).
