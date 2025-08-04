# Personal Finance Manager Service

## Firefly III

- [Official Site](https://www.firefly-iii.org/)

### Deployment

- [Deployment documentation](https://docs.firefly-iii.org/how-to/firefly-iii/installation/docker/)

Docker compose file and environments files are provided by the software owner.

Download the docker compose:

```sh
wget https://raw.githubusercontent.com/firefly-iii/docker/main/docker-compose.yml -O docker-compose.yml
```

Download environments:

```sh
wget https://raw.githubusercontent.com/firefly-iii/firefly-iii/main/.env.example -O .env.example
wget https://raw.githubusercontent.com/firefly-iii/docker/main/database.env -O .db.env.example
```

### Backup and restore

- [Community solution](https://gist.github.com/ddyykk/84bc588d6de1d346fbf473af49c34cf0)

Remenber to run this commands on a user with access to Docker.

Make backup.

```shell
wget https://gist.githubusercontent.com/ddyykk/84bc588d6de1d346fbf473af49c34cf0/raw/dfcb787a7f6fb17193f3a56bdfd7683476e6abbb/backup_firefly_docker.sh
chmod +x backup_firefly_docker.sh
./backup_firefly_docker.sh
```

Restore backup.

```shell
wget https://gist.githubusercontent.com/ddyykk/84bc588d6de1d346fbf473af49c34cf0/raw/dfcb787a7f6fb17193f3a56bdfd7683476e6abbb/restore_firefly_docker.sh
chmod +x restore_firefly_docker.sh
./restore_firefly_docker.sh ./firefly_backups/backup.tar.gz
```

### Web browser interfaces

- [Firefly III](http://localhost)

---
