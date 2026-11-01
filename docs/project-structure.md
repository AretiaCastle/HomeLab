# Project structure

```text
HomeLab/
├── makefile              # Entry point for every action
├── AGENTS.md             # Guidelines for AI agents (imported by CLAUDE.md)
├── requirements.txt      # Commands checked by `make check`
├── .env                  # Global configuration
├── logs/                 # Logs of every make execution
├── docs/                 # Internal documentation
├── lib/
│   ├── backup.sh         # Shared backup functions
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
   volumes and backups, and the backup retention and schedule.
2. `services/<service>/.env` (optional): values of that service. It can use and
   override the global ones.

`make` loads both files, in that order, before running the service script.
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

## Adding a service

1. Create `services/<service>/` following the layout above.
2. Add the five targets to the `makefile` using the `deploy_service`,
   `stop_service`, `clean_service`, `backup_service` and `restore_service`
   functions.
3. Publish the ports the service needs and do not attach it to external
   docker networks (see [architecture](architecture.md)).
