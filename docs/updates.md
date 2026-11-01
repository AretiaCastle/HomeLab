# Updates

Every image of the compose files has a fixed version tag, never `latest`. The
repository defines the versions deployed, so every host runs the same tested
versions and each update is a commit.

## New versions

[Dependabot](../.github/dependabot.yml) checks the images of the compose files
every week and opens a pull request for each new version. Before merging it,
read the release notes of the application: major versions may need manual
steps or change the configuration.

### Known limitations

These images may not get pull requests and must be checked by hand until the
limitation is solved:

| Image | Where | Limitation | Possible improvement |
| ----- | ----- | ---------- | -------------------- |
| `alpine` | `BACKUP_HELPER_IMAGE` in [lib/backup.sh](../lib/backup.sh) | Dependabot only reads compose files, not shell scripts | Move the helper image to a file Dependabot reads, or use a [Renovate](https://docs.renovatebot.com/) regex manager |
| `lscr.io/linuxserver/duckdns` | [duckdns compose](../services/external_ddns/duckdns/docker-compose.yml) | Tags are a commit hash plus a build number (`8aabc87c-ls95`), not a version Dependabot can compare. Not verified yet whether it opens pull requests for it | If no pull requests arrive, check the [published tags](https://hub.docker.com/r/linuxserver/duckdns/tags) by hand or use Renovate, which supports custom versioning |

When a limitation is solved, remove it from this table.

## Update a service

On each host, after pulling the repository:

```bash
git pull
make update-<service>
```

`update-<service>` makes a backup of the service and, only if it succeeds,
pulls the images of its compose files and recreates the containers whose image
changed. Data stays in the volumes.

## Rollback

If the new version fails, go back to the previous tag and restore the backup
made before the update, which matches the previous version:

```bash
git revert <update commit>   # or set the previous tag in the compose file
make update-<service>
make restore-<service> BACKUP=volumes-<timestamp before the update>.tar.gz
```

The `update-<service>` of the rollback makes a backup of the failed version
first, so restore the previous one by name.
