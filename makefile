.PHONY: help check check_env check_commands status logs \
		backup-all schedule-backups unschedule-backups \
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
SERVICES := external_ddns dns vpn ingress torrent pfm
BACKUP_CRON_MARKER := \# HomeLab backup-all

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

# Restore service. The backup file name is taken from BACKUP, if it is empty
# the newest backup is restored.
# $(1): Display name (e.g. Ingress)
# $(2): Service directory (e.g. ingress)
# $(3): Script name (e.g. ingress.sh)
define restore_service
	@$(call log, Restoring backup of $(1) service...)
	@$(call load_env,$(2)); \
	bash $(SERVICES_DIR)/$(2)/$(3) restore "$(BACKUP)"
	@$(call log, Backup restored for $(1) service)
endef

################################################################################
# Targets

######################
## Standard actions ##
######################

# Default target
help:
	@cat $(BASE_DIR)/statics/help.txt

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
stop-external_ddns: check
	$(call stop_service,External DDNS,external_ddns,external_ddns.sh)
clean-external_ddns: check
	$(call clean_service,External DDNS,external_ddns,external_ddns.sh)
backup-external_ddns: check
	$(call backup_service,External DDNS,external_ddns,external_ddns.sh)
restore-external_ddns: check
	$(call restore_service,External DDNS,external_ddns,external_ddns.sh)

# DNS
dns: check
	$(call deploy_service,DNS,dns,dns.sh)
stop-dns: check
	$(call stop_service,DNS,dns,dns.sh)
clean-dns: check
	$(call clean_service,DNS,dns,dns.sh)
backup-dns: check
	$(call backup_service,DNS,dns,dns.sh)
restore-dns: check
	$(call restore_service,DNS,dns,dns.sh)

# VPN
vpn: check
	$(call deploy_service,VPN,vpn,vpn.sh)
stop-vpn: check
	$(call stop_service,VPN,vpn,vpn.sh)
clean-vpn: check
	$(call clean_service,VPN,vpn,vpn.sh)
backup-vpn: check
	$(call backup_service,VPN,vpn,vpn.sh)
restore-vpn: check
	$(call restore_service,VPN,vpn,vpn.sh)

# Ingress
ingress: check
	$(call deploy_service,Ingress,ingress,ingress.sh)
stop-ingress: check
	$(call stop_service,Ingress,ingress,ingress.sh)
clean-ingress: check
	$(call clean_service,Ingress,ingress,ingress.sh)
backup-ingress: check
	$(call backup_service,Ingress,ingress,ingress.sh)
restore-ingress: check
	$(call restore_service,Ingress,ingress,ingress.sh)

# Torrent
torrent: check
	$(call deploy_service,Torrent,torrent,torrent.sh)
stop-torrent: check
	$(call stop_service,Torrent,torrent,torrent.sh)
clean-torrent: check
	$(call clean_service,Torrent,torrent,torrent.sh)
backup-torrent: check
	$(call backup_service,Torrent,torrent,torrent.sh)
restore-torrent: check
	$(call restore_service,Torrent,torrent,torrent.sh)

# Personal Finance Manager
pfm: check
	$(call deploy_service,Personal Finance Manager,pfm,pfm.sh)
stop-pfm: check
	$(call stop_service,Personal Finance Manager,pfm,pfm.sh)
clean-pfm: check
	$(call clean_service,Personal Finance Manager,pfm,pfm.sh)
backup-pfm: check
	$(call backup_service,Personal Finance Manager,pfm,pfm.sh)
restore-pfm: check
	$(call restore_service,Personal Finance Manager,pfm,pfm.sh)

#####################
## Backup actions ##
#####################

# Backup of every service, keeps going if one of them fails
backup-all: check
	@$(call log, Creating backup of all services...)
	@failed=""; \
	for service in $(SERVICES); do \
		$(MAKE) --no-print-directory backup-$$service LOG_FILE=$(LOG_FILE) || failed="$$failed $$service"; \
	done; \
	if [ -n "$$failed" ]; then \
		$(call log, ERROR: backup failed for:$$failed); \
		exit 1; \
	fi
	@$(call log, Backup of all services finished)

# Install (or replace) the cron task that runs backup-all on BACKUP_SCHEDULE
schedule-backups: check
	@$(call load_env,); \
	cron_filepath="$${CRON_FILEPATH:-/etc/crontab}"; \
	cron_task="$${BACKUP_SCHEDULE:-30 3 * * *}   $$USER    make -C $(BASE_DIR) backup-all >> $(LOG_DIR)/backup-all.log 2>&1 $(BACKUP_CRON_MARKER)"; \
	sudo sed -i '/$(BACKUP_CRON_MARKER)$$/d' "$$cron_filepath"; \
	echo "$$cron_task" | sudo tee -a "$$cron_filepath" > /dev/null; \
	$(call log, Backups scheduled in $$cron_filepath: $$cron_task)

unschedule-backups: check
	@$(call load_env,); \
	cron_filepath="$${CRON_FILEPATH:-/etc/crontab}"; \
	sudo sed -i '/$(BACKUP_CRON_MARKER)$$/d' "$$cron_filepath"; \
	$(call log, Backups unscheduled from $$cron_filepath)

#################################
## Management and Logs actions ##
#################################
# Containers of every compose project named "$PROJECT-<tool>"
status:
	@$(call load_env,); \
	docker ps -a --filter "label=com.docker.compose.project" \
		--format 'table {{.Label "com.docker.compose.project"}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}' \
		| awk -v prefix="$$PROJECT-" 'NR == 1 || index($$1, prefix) == 1'

logs:
	@if [ -z "$(CONTAINER)" ]; then \
		echo "ERROR: Specify CONTAINER=<name>"; \
		echo "Example: make logs CONTAINER=pihole"; \
		exit 1; \
	fi
	@docker logs -f $(CONTAINER)

################################################################################
