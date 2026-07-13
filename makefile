.PHONY: help check \ 
		deploy-all deploy-network deploy-media deploy-finance \
        stop clean status logs \
		external_ddns stop-external_ddns clean-external_ddns backup-external_ddns restore-external_ddns \
		dns stop-dns clean-dns backup-dns restore-dns \
		ingress stop-ingress clean-ingress backup-ingress restore-ingress \
		vpn stop-vpn clean-vpn backup-vpn restore-vpn \
		torrent stop-torrent clean-torrent backup-torrent restore-torrent \
		pfm stop-pfm clean-pfm backup-pfm restore-pfm

# Constants
BASE_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
SERVICES_DIR := $(BASE_DIR)/services
ENV_FILE := $(BASE_DIR)/.env
LOG_DIR := $(BASE_DIR)/logs
LOG_FILE := $(LOG_DIR)/log-$(shell date +%Y%m%d_%H-%M-%S).log

################################################################################
# Functions

# Logging function
define log
	mkdir -p $(LOG_DIR); \
	echo "[$(shell date '+%Y-%m-%d %H:%M:%S')] $(1)" | tee -a $(LOG_FILE)
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

# Load environment variables from root .env and optional service .env.
# $(1): service directory under services (e.g. ingress)
define load_env
	set -a; \
	[ -f "$(ENV_FILE)" ] && . "$(ENV_FILE)"; \
	[ -n "$(1)" ] && [ -f "$(SERVICES_DIR)/$(1)/.env" ] && . "$(SERVICES_DIR)/$(1)/.env"; \
	set +a
endef

# Deploy service.
# $(1): Display name (e.g. Ingress)
# $(2): Service directory (e.g. ingress)
# $(3): Script name (e.g. ingress.sh)
define deploy_service
	@$(call log, Deploying $(1) service...)
	@$(call load_env,$(2)); \
	bash $(SERVICES_DIR)/$(2)/$(3) deploy
	@$(call log, $(1) service deployed successfully)
endef

# Stop service.
# $(1): Display name (e.g. Ingress)
# $(2): Service directory (e.g. ingress)
# $(3): Script name (e.g. ingress.sh)
define stop_service
	@$(call log, Stopping $(1) service...)
	@$(call load_env,$(2)); \
	bash $(SERVICES_DIR)/$(2)/$(3) stop
	@$(call log, $(1) service stopped successfully)
endef

# Clean service.
# $(1): Display name (e.g. Ingress)
# $(2): Service directory (e.g. ingress)
# $(3): Script name (e.g. ingress.sh)
define clean_service
	@$(call log, Cleaning $(1) service...)
	@$(call load_env,$(2)); \
	bash $(SERVICES_DIR)/$(2)/$(3) clean
	@$(call log, $(1) service cleaned successfully)
endef

# Backup service.
# $(1): Display name (e.g. Ingress)
# $(2): Service directory (e.g. ingress)
# $(3): Script name (e.g. ingress.sh)
define backup_service
	@$(call log, Creating backup for $(1) service...)
	@$(call load_env,$(2)); \
	bash $(SERVICES_DIR)/$(2)/$(3) backup
	@$(call log, Backup for $(1) service finished)
endef

# Restore service.
# $(1): Display name (e.g. Ingress)
# $(2): Service directory (e.g. ingress)
# $(3): Script name (e.g. ingress.sh)
define restore_service
	@$(call log, Restoring backup of $(1) service...)
	@$(call load_env,$(2)); \
	bash $(SERVICES_DIR)/$(2)/$(3) restore
	@$(call log, Backup restored for $(1) service)
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
	$(call deploy_service,External DDNS,external_ddns,external_ddns.sh)
stop-external_ddns:
	$(call stop_service,External DDNS,external_ddns,external_ddns.sh)
clean-external_ddns:
	$(call clean_service,External DDNS,external_ddns,external_ddns.sh)
backup-external_ddns:
	$(call backup_service,External DDNS,external_ddns,external_ddns.sh)
restore-external_ddns:
	$(call restore_service,External DDNS,external_ddns,external_ddns.sh)

# DNS
dns: check
	$(call deploy_service,DNS,dns,dns.sh)
stop-dns:
	$(call stop_service,DNS,dns,dns.sh)
clean-dns:
	$(call clean_service,DNS,dns,dns.sh)
backup-dns:
	$(call backup_service,DNS,dns,dns.sh)
restore-dns:
	$(call restore_service,DNS,dns,dns.sh)

# VPN
vpn: check
	$(call deploy_service,VPN,vpn,vpn.sh)
stop-vpn:
	$(call stop_service,VPN,vpn,vpn.sh)
clean-vpn:
	$(call clean_service,VPN,vpn,vpn.sh)
backup-vpn:
	$(call backup_service,VPN,vpn,vpn.sh)
restore-vpn:
	$(call restore_service,VPN,vpn,vpn.sh)

# Ingress
ingress: check
	$(call deploy_service,Ingress,ingress,ingress.sh)
stop-ingress:
	$(call stop_service,Ingress,ingress,ingress.sh)
clean-ingress:
	$(call clean_service,Ingress,ingress,ingress.sh)
backup-ingress:
	$(call backup_service,Ingress,ingress,ingress.sh)
restore-ingress:
	$(call restore_service,Ingress,ingress,ingress.sh)

# Torrent
torrent: check
	$(call deploy_service,Torrent,torrent,torrent.sh)
stop-torrent:
	$(call stop_service,Torrent,torrent,torrent.sh)
clean-torrent:
	$(call clean_service,Torrent,torrent,torrent.sh)
backup-torrent:
	$(call backup_service,Torrent,torrent,torrent.sh)
restore-torrent:
	$(call restore_service,Torrent,torrent,torrent.sh)

# Personal Finance Manager
pfm: check
	$(call deploy_service,Personal Finance Manager,pfm,pfm.sh)
stop-pfm:
	$(call stop_service,Personal Finance Manager,pfm,pfm.sh)
clean-pfm:
	$(call clean_service,Personal Finance Manager,pfm,pfm.sh)
backup-pfm:
	$(call backup_service,Personal Finance Manager,pfm,pfm.sh)
restore-pfm:
	$(call restore_service,Personal Finance Manager,pfm,pfm.sh)

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

################################################################################
