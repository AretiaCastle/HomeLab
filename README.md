# HomeLab

Deployment and management of the services of a home lab, driven by `make` and
mostly based on docker compose.

Services are independent from each other, so they can be deployed all on the
same host or spread across several ones. See [architecture](docs/architecture.md).

## Services

| Service         | Tools                                        |
| --------------- | -------------------------------------------- |
| `vpn`           | WireGuard + WGDashboard                      |
| `dns`           | Pi-hole                                      |
| `ingress`       | Nginx Proxy Manager                          |
| `external_ddns` | Duck DNS                                     |
| `pfm`           | Firefly III                                  |
| `torrent`       | qBittorrent, Jackett, Sonarr, Radarr (WIP)   |
| `drive`         | Nextcloud (WIP)                              |

Each service has its own documentation in `services/<service>/<service>.md`.

## Usage

Requirements: `docker`, `curl` and `git`. Check them with:

```bash
make check
```

Every service has the same set of actions:

```bash
make <service>           # Deploy
make stop-<service>      # Stop
make clean-<service>     # Stop and remove containers and volumes
make backup-<service>    # Create a backup
make restore-<service>   # Restore the newest backup
make update-<service>    # Backup and update to the repository image versions
```

Backups of all the services deployed on the host can be scheduled with
`make schedule-backups` and copied to a remote host such as a NAS.

For example:

```bash
make vpn
make dns
make ingress
```

Run `make help` for the full list of targets.

## Documentation

- [Architecture](docs/architecture.md): deployment, networking and ports.
- [Backups](docs/backups.md): backup types, restore, retention, remote copy
  and scheduling.
- [Updates](docs/updates.md): image versions, updates and rollback.
- [Project structure](docs/project-structure.md): layout, environment files and
  how to add a service.

---

## LICENSE

This software is licensed under Creative Commons
Attribution-NonCommercial-ShareAlike 4.0 International. You may not use this
software except in compliance with this license.

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.

HomeLab © 2025 by Hugo Pascual Adán is licensed under Creative Commons
Attribution-NonCommercial-ShareAlike 4.0 International.
