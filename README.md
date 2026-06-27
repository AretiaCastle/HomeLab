# HomeLab

Home services local deployment and management system.

## Quick Start

```bash
# Copy environment template
cp .env.example .env

# Edit with your configuration
nano .env

# Check requirements
make check

# Deploy all services
make deploy-all
```

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

```
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

## Migration

If you're upgrading from the old `deployment/` and `documentation/` structure:

```bash
./reorganize.sh
```

This combines deployment and documentation into the new `services/` directory.

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
