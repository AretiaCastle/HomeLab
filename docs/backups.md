# Backups

Backups are made per tool and stored in its backup directory (e.g.
`$DEPLOYMENTS_BACKUPS_PATH/pihole`). Common logic lives in
[lib/backup.sh](../lib/backup.sh).

## Backup types

| File                         | Type          | Description                                                  |
| ---------------------------- | ------------- | ------------------------------------------------------------ |
| `volumes-<timestamp>.tar.gz` | Cold copy     | Whole volumes directory of the tool, taken with it stopped   |
| `export-<timestamp>.<ext>`   | Application   | Native export of the application, portable between versions |

Every file has its `<file>.sha256`, checked before any restore.

- **Cold copy**: every docker tool has it. The compose project is stopped, the
  volumes directory (`$DEPLOYMENTS_DOCKER_VOLUMES/<tool>`) is archived from a
  helper container (so files owned by any user are included with their
  ownership) and the project is started again if it was running. It is the
  complete and consistent copy of the tool.
- **Application export**: only for tools with a native export, made before the
  cold copy while the application is running. Useful to restore into a newer
  version or a fresh installation.

| Service   | Tool                | Cold copy | Export                          |
| --------- | ------------------- | --------- | ------------------------------- |
| `dns`     | Pi-hole             | ✅        | Teleporter (`.zip`)             |
| `ingress` | Nginx Proxy Manager | ✅        | —                               |
| `pfm`     | Firefly III         | ✅        | Database dump + uploads (`.tar.gz`) |

Tools that are not deployed on the host are skipped.

## Usage

```bash
make backup-<service>                    # Export (if any) + cold copy
make restore-<service>                   # Restore the newest cold copy
make restore-<service> BACKUP=<file>     # Restore a given cold copy or export
make backup-all                          # Backup of every service
```

Restoring a cold copy replaces the whole volumes directory. Restoring an
export imports it into the running application.

To restore on a new host, deploy the service first and then restore it.

## Retention

After each backup only the newest `BACKUP_RETENTION` (global `.env`, 7 by
default) files of each type are kept.

## Scheduling

```bash
make schedule-backups     # Run backup-all on BACKUP_SCHEDULE
make unschedule-backups   # Remove the scheduled task
```

`schedule-backups` adds a single task to `CRON_FILEPATH` (`/etc/crontab` by
default) using the cron expression in `BACKUP_SCHEDULE` (`30 3 * * *` by
default). Running it again replaces the task. The output of each run is
appended to `logs/backup-all.log`.

## Adding backups to a tool

In the tool script, using its compose project, volumes directory and backup
directory:

```bash
<tool>_backup_docker(){
    if ! docker_project_deployed "$<TOOL>_COMPOSE_PROJECT"; then
        echo "<Tool> is not deployed, skipping backup"
        return 0
    fi

    docker_volumes_backup "$<TOOL>_COMPOSE_PROJECT" "$<TOOL>_BASE_VOLUMES_PATH" "$<TOOL>_BACKUP_PATH" || exit 1
}

# $1 Backup file name (optional, newest volumes backup by default)
<tool>_restore_docker(){
    docker_restore "$<TOOL>_COMPOSE_PROJECT" "$<TOOL>_BASE_VOLUMES_PATH" "$<TOOL>_BACKUP_PATH" "$1" || exit 1
}
```

For an application export, create `export-$(backup_timestamp).<ext>` in the
backup directory, then call `backup_write_checksum` and `backup_prune <dir>
export`. Pass the import function as the last argument of `docker_restore`.
