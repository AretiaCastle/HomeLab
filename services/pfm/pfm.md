# Personal Finance Manager Service

## Firefly III

- [Official Site](https://www.firefly-iii.org/)

### Deployment

#### Docker Compose

- [Deployment documentation](https://docs.firefly-iii.org/how-to/firefly-iii/installation/docker/)

Docker compose file and environments files are provided by the software owner.

```shell
docker compose up -d
```

### Backup and restore

Besides the cold copy of its volumes, the backup includes an export with a
database dump and the uploads directory. See [backups](../../docs/backups.md).

```shell
make backup-pfm
make restore-pfm                                  # Newest cold copy
make restore-pfm BACKUP=export-<timestamp>.tar.gz # Import an export
```

### Web browser interfaces

- [Firefly III](http://localhost:10101)

---
