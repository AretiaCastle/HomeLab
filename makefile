# Services with a services/<service>/<service>.sh script
SERVICES := external_ddns dns vpn ingress torrent pfm

.PHONY: help check status logs \
		backup-all schedule-backups unschedule-backups \
		setup-remote-backups sync-backups fetch-backups \
		$(SERVICES) \
		$(addprefix stop-,$(SERVICES)) \
		$(addprefix clean-,$(SERVICES)) \
		$(addprefix backup-,$(SERVICES)) \
		$(addprefix restore-,$(SERVICES)) \
		$(addprefix update-,$(SERVICES))

# Keep the exit code of the commands piped to the log file
SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c

# Constants
BASE_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
LOG_DIR := $(BASE_DIR)/logs
ENV_FILE := $(BASE_DIR)/.env
export ENV_FILE

# One log file per execution, named after the target
ifndef LOG_FILE
LOG_FILE := $(LOG_DIR)/$(shell date +%Y%m%d_%H%M%S)-$(or $(firstword $(MAKECMDGOALS)),help).log
endif
export LOG_FILE

# Run the entry point with its output also appended to the log file
RUN := mkdir -p $(LOG_DIR) && bash $(BASE_DIR)/scripts/homelab.sh
TO_LOG := 2>&1 | tee -a $(LOG_FILE)

################################################################################
# Targets

# Default target
help:
	@cat $(BASE_DIR)/statics/help.txt

check:
	@$(RUN) check $(TO_LOG)

######################
## Services actions ##
######################

$(SERVICES): check
	@$(RUN) service $@ deploy $(TO_LOG)

$(addprefix stop-,$(SERVICES)): stop-%: check
	@$(RUN) service $* stop $(TO_LOG)

$(addprefix clean-,$(SERVICES)): clean-%: check
	@$(RUN) service $* clean $(TO_LOG)

$(addprefix backup-,$(SERVICES)): backup-%: check
	@$(RUN) service $* backup $(TO_LOG)

$(addprefix restore-,$(SERVICES)): restore-%: check
	@$(RUN) service $* restore "$(BACKUP)" $(TO_LOG)

# Backup and then update to the image versions of the compose files
$(addprefix update-,$(SERVICES)): update-%: check
	@$(RUN) update $* $(TO_LOG)

#####################
## Backup actions ##
#####################

backup-all: check
	@$(RUN) backup-all $(SERVICES) $(TO_LOG)

setup-remote-backups: check
	@$(RUN) remote setup $(TO_LOG)

sync-backups: check
	@$(RUN) remote sync $(TO_LOG)

fetch-backups: check
	@$(RUN) remote fetch $(TO_LOG)

schedule-backups: check
	@$(RUN) schedule $(TO_LOG)

unschedule-backups: check
	@$(RUN) unschedule $(TO_LOG)

#################################
## Management and Logs actions ##
#################################

status: check
	@$(RUN) status

logs:
	@if [ -z "$(CONTAINER)" ]; then \
		echo "ERROR: Specify CONTAINER=<name>"; \
		echo "Example: make logs CONTAINER=pihole"; \
		exit 1; \
	fi
	@docker logs -f $(CONTAINER)

################################################################################
