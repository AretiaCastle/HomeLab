# HomeLab

Home services local deployment and management system.

## Quick Start

```bash
# Copy global environment template
cp .env.example .env

# Copy per-service templates (only for services you are going to use)
cp services/dns/.env.example services/dns/.env
cp services/external_ddns/.env.example services/external_ddns/.env
cp services/ingress/.env.example services/ingress/.env
cp services/vpn/.env.example services/vpn/.env
cp services/pfm/.env.example services/pfm/.env

# Edit with your configuration
nano .env
nano services/ingress/.env

# Check requirements
make check

# Deploy all services
make deploy-all
```

## Environment Files

HomeLab now uses layered environment files:

- Global: `.env`
- Per service: `services/<service>/.env`

Load order and priority:

1. `.env` (required)
2. `services/<service>/.env` (optional, overrides global values)

`make` loads both files before executing each service script.

This allows shared variables (paths, project name) in the global file and service-specific settings in each service file.

## Available Services

- **DNS**: PiHole + Dynamic DNS (Duck DNS)
- **Ingress**: Nginx reverse proxy with SSL
- **VPN**: Wireguard + Web Dashboard
- **Media**: Torrent stack (qBittorrent, Sonarr, Radarr, Jackett)
- **Finance**: Firefly III personal finance manager

## Usage

See all available commands:

```bash
make help
```

Deploy specific services:

```bash
make dns        # Deploy PiHole
make ingress    # Deploy Nginx
make vpn        # Deploy Wireguard
make torrent    # Deploy media stack
```

Deploy predefined groups:

```bash
make deploy-network   # DNS + Ingress + VPN
make deploy-media     # Torrent stack
make deploy-finance   # Firefly III
```

Management commands:

```bash
make status           # View container status
make logs-dns         # View PiHole logs
make stop             # Stop all services
make clean            # Stop and remove containers
```

## Project Structure

```text
HomeLab/
├── makefile              # Main deployment orchestration
├── .env                  # Environment configuration (create from .env.example)
├── requirements.txt      # Required system commands
├── help.txt             # Command reference
├── logs/                # Deployment logs
└── services/            # Service definitions (deployment + docs)
    ├── dns/
    ├── ingress/
    ├── personal_finance_manager/
    ├── torrent/
    └── vpn/
```

See [SERVICES_STRUCTURE.md](SERVICES_STRUCTURE.md) for detailed service organization.

---

## LICENSE

This software is licensed under Creative Common
Attribution-NonCommercial-ShareAlike 4.0 International. You may not use this
software except in compliance with this license.

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.

home_services © 2025 by Hugo Pascual Adán and Inés Garrido Lozano is licensed
under Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International.
