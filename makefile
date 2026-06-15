.PHONY: help check \ 
		deploy-all deploy-network deploy-media deploy-finance \
        dns ingress vpn torrent pfm \
        status logs logs-all logs-tail logs-dns logs-ingress logs-vpn logs-torrent logs-pfm stop clean

# Constants
PROJECT_NAME := AretiaLab
BASE_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
SERVICES_DIR := $(BASE_DIR)/services
ENV_FILE := $(BASE_DIR)/.env
LOG_DIR := $(BASE_DIR)/logs
LOG_FILE := $(LOG_DIR)/deployment-$(shell date +%Y%m%d).log

################################################################################
# Functions

# Logging function
define log
	mkdir -p $(LOG_DIR); \
	echo "[$(shell date '+%Y-%m-%d %H:%M:%S')] $(1)" | tee -a $(LOG_FILE)
endef

# Load environment variables from .env file
define load_env
	set -a; \
	[ -f "$(ENV_FILE)" ] && . "$(ENV_FILE)"; \
	set +a
endef

# Load environment and execute deployment
define deploy_service
	@$(call log,Deploying $(1)...)
	@$(load_env); \
	cd $(SERVICES_DIR)/$(2) && \
	docker compose -p $(PROJECT_NAME) up -d && \
	$(call log,✓ $(1) deployed successfully)
endef

################################################################################
# Actions

######################
## Standard actions ##
######################

# Default target
help:
	@cat $(BASE_DIR)/help.txt

# Check requirements
check:
	@$(call log,Checking requirements...)

	# Verify existance of .env file
	@if [ ! -f "$(ENV_FILE)" ]; then \
		$(call log,ERROR: .env file not found); \
		$(call log,Please copy .env.example to .env and configure your secrets); \
		exit 1; \
	fi

	# Check software requirements installed
	@if [ ! -f "requirements.txt" ]; then \
		$(call log,WARNING: requirements.txt not found); \
	else \
		$(call log,Checking required commands...); \
		while IFS= read -r cmd || [ -n "$$cmd" ]; do \
			[ -z "$$cmd" ] || echo "$$cmd" | grep -q "^#" && continue; \
			cmd=$$(echo "$$cmd" | xargs); \
			if ! command -v "$$cmd" >/dev/null 2>&1; then \
				$(call log,✗ $$cmd is not installed); \
				exit 1; \
			else \
				$(call log,✓ $$cmd); \
			fi; \
		done < requirements.txt; \
	fi
	
	@$(call log,All requirements satisfied)

########################
## Deployment actions ##
########################

# Individual services
dns: check
	@$(call log,Deploying DNS service...)
	@$(load_env); \
	@bash $(SERVICES_DIR)/dns/dns.sh
	$(call log,DNS service deployed successfully)

vpn: check
	@$(call log,Deploying VPN service...)	
	@$(load_env); \
	@bash $(SERVICES_DIR)/vpn/vpn.sh
	$(call log,VPN service deployed successfully)

external_ddns: check
	@$(call log,Configuring External DDNS service...)	
	@$(load_env); \
	@bash $(SERVICES_DIR)/external_ddns/external_ddns.sh
	$(call log,DNS service deployed successfully)

ingress: check
	@$(call log, Ingress service is WIP)

torrent: check
	@$(call log, Torrent service is WIP)

pfm: check
	@$(call log, Personal finance manager service is WIP)

# Predefined groups
deploy-network: dns ingress vpn
	@$(call log, deploy-network is WIP)

deploy-media: torrent
	@$(call log, deploy-media is WIP)

deploy-finance: pfm
	@$(call log, deploy-finance is WIP)

# Deploy all services
deploy-all: check deploy-network deploy-media deploy-finance
	@$(call log, deploy-all is WIP)

#################################
## Management and Logs actions ##
#################################

status:
	@$(call log,Container status:)
	@docker compose -p $(PROJECT_NAME) ps

stop:
	@$(call log,Stopping all services...)
	@find $(SERVICES_DIR) -name "docker-compose.yml" -type f -execdir docker compose -p $(PROJECT_NAME) stop \;
	@$(call log,✓ Services stopped)

clean:
	@$(call log,Stopping and cleaning containers...)
	@find $(SERVICES_DIR) -name "docker-compose.yml" -type f -execdir docker compose -p $(PROJECT_NAME) down \;
	@$(call log,✓ Cleanup completed)

logs:
	@if [ -z "$(SERVICE)" ]; then \
		$(call log,ERROR: Specify SERVICE=<name>); \
		echo "Example: make logs SERVICE=nginx"; \
		exit 1; \
	fi
	@docker compose -p $(PROJECT_NAME) logs -f $(SERVICE)

logs-dns: SERVICE=pihole
logs-dns: logs

logs-ingress: SERVICE=nginx
logs-ingress: logs

logs-vpn: SERVICE=wireguard
logs-vpn: logs

logs-torrent: SERVICE=qbittorrent
logs-torrent: logs

logs-pfm: SERVICE=firefly
logs-pfm: logs

logs-all:
	@docker compose -p $(PROJECT_NAME) logs -f

logs-tail:
	@docker compose -p $(PROJECT_NAME) logs --tail=$${LINES:-50} $(SERVICE)
