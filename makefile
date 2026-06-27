.PHONY: help check \ 
		deploy-all deploy-network deploy-media deploy-finance \
        stop clean status logs \
		external_ddns stop-external_ddns clean-external_ddns \
		dns stop-dns clean-dns \
		ingress stop-ingress clean-ingress \
		vpn stop-vpn clean-vpn \
		torrent stop-torrent clean-torrent \
		pfm stop-pfm clean-pfm

# Constants
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

##
# @Description
# Import all the scripts recursively from the objective folder
# @Parameters
# $1 Directory to import scripts from
##
define import_from_dir
	for file in $$(find $(1) -type f -name "*.sh" -print | sort); do \
		. "$$file"; \
	done
endef

# Deploy service.
# $(1): Display name (e.g. Ingress)
# $(2): Script path relative to $(SERVICES_DIR) (e.g. ingress/ingress.sh)
define deploy_service
	@$(call log, Deploying $(1) service...)
	@$(load_env); \
	bash $(SERVICES_DIR)/$(2) deploy
	@$(call log, $(1) service deployed successfully)
endef

# Stop service.
# $(1): Display name (e.g. Ingress)
# $(2): Script path relative to $(SERVICES_DIR) (e.g. ingress/ingress.sh)
define stop_service
	@$(call log, Stopping $(1) service...)
	@$(load_env); \
	bash $(SERVICES_DIR)/$(2) stop
	@$(call log, $(1) service stopped successfully)
endef

# Clean service.
# $(1): Display name (e.g. Ingress)
# $(2): Script path relative to $(SERVICES_DIR) (e.g. ingress/ingress.sh)
define clean_service
	@$(call log, Cleaning $(1) service...)
	@$(load_env); \
	bash $(SERVICES_DIR)/$(2) clean
	@$(call log, $(1) service cleaned successfully)
endef

################################################################################
# Targets

######################
## Standard actions ##
######################

# Default target
help:
	@cat $(BASE_DIR)/help.txt

# Check requirements
check_env:
	@if [ ! -f "$(ENV_FILE)" ]; then \
		$(call log, ERROR: .env file not found); \
		$(call log, Please copy .env.example to .env and configure your secrets); \
		exit 1; \
	fi

check_commands:
	# Check software requirements installed
	@if [ ! -f "requirements.txt" ]; then \
		$(call log, WARNING: requirements.txt not found); \
	else \
		$(call log, Checking required commands...); \
		while IFS= read -r cmd || [ -n "$$cmd" ]; do \
			[ -z "$$cmd" ] || echo "$$cmd" | grep -q "^#" && continue; \
			cmd=$$(echo "$$cmd" | xargs); \
			if ! command -v "$$cmd" >/dev/null 2>&1; then \
				$(call log,✗ $$cmd is not installed); \
				exit 1; \
			else \
				$(call log,$$cmd); \
			fi; \
		done < requirements.txt; \
	fi

check:
	@$(call log, Checking requirements...)
	@$(MAKE) check_env
	@$(MAKE) check_commands	
	@$(call log, All requirements satisfied)

######################
## Services actions ##
######################

# External DDNS
external_ddns: check
	$(call deploy_service,External DDNS,external_ddns/external_ddns.sh)
stop-external_ddns:
	$(call stop_service,External DDNS,external_ddns/external_ddns.sh)
clean-external_ddns:
	$(call clean_service,External DDNS,external_ddns/external_ddns.sh)

# DNS
dns: check
	$(call deploy_service,DNS,dns/dns.sh)
stop-dns:
	$(call stop_service,DNS,dns/dns.sh)
clean-dns:
	$(call clean_service,DNS,dns/dns.sh)

# VPN
vpn: check
	$(call deploy_service,VPN,vpn/vpn.sh)
stop-vpn:
	$(call stop_service,VPN,vpn/vpn.sh)
clean-vpn:
	$(call clean_service,VPN,vpn/vpn.sh)

# Ingress
ingress: check
	$(call deploy_service,Ingress,ingress/ingress.sh)
stop-ingress:
	$(call stop_service,Ingress,ingress/ingress.sh)
clean-ingress:
	$(call clean_service,Ingress,ingress/ingress.sh)

# Torrent
torrent: check
	$(call deploy_service,Torrent,torrent/torrent.sh)
stop-torrent:
	$(call stop_service,Torrent,torrent/torrent.sh)
clean-torrent:
	$(call clean_service,Torrent,torrent/torrent.sh)

# Personal Finance Manager
pfm: check
	$(call deploy_service,Personal Finance Manager,pfm/pfm.sh)
stop-pfm:
	$(call stop_service,Personal Finance Manager,pfm/pfm.sh)
clean-pfm:
	$(call clean_service,Personal Finance Manager,pfm/pfm.sh)

# Predefined groups
deploy-network: 
	@$(call log, Deploying network services)
	@$(call log, WIP)
	@$(call log, Deployed network services)

deploy-media: torrent
	@$(call log, Deploying media services)
	@$(call log, WIP)
	@$(call log, Deployed media services)

# Deploy all services
deploy-all: 
	@$(call log, Deploying all automatized services)
	@$(call log, WIP)
	@$(call log, Deployed all automatized services)

#################################
## Management and Logs actions ##
#################################
status:
	@$(call log,Container status:)
	@docker compose -p $(PROJECT_NAME) ps

logs:
	@if [ -z "$(SERVICE)" ]; then \
		$(call log,ERROR: Specify SERVICE=<name>); \
		echo "Example: make logs SERVICE=nginx-proxy-manager"; \
		exit 1; \
	fi
	@docker compose -p $(PROJECT_NAME) logs -f $(SERVICE)
