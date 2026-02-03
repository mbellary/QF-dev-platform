SHELL := /bin/bash
.DEFAULT_GOAL := help

help:
	@echo ""
	@echo "Infra:"
	@echo "  make infra-up        Start LocalStack and infra"
	@echo "  make infra-down"
	@echo ""
	@echo "Apps:"
	@echo "  make all-up          Start all app services"
	@echo "  make all-down"
	@echo ""
	@echo "Logs:"
	@echo "  make logs            Tail logs from all apps"
	@echo "  make logs-downloader"
	@echo "  make logs-processor"
	@echo "  make logs-extractor"
	@echo "  make logs-transformer"
	@echo ""
	@echo "Debug:"
	@echo "  make status"
	@echo "  make logs-last"
	@echo ""


ROOT_DIR := $(shell pwd)

APPS := downloader

# DOWNLOADER_COMPOSE := docker compose \
# 	--project-directory $(ROOT_DIR)/downloader \
# 	-f $(ROOT_DIR)/downloader/docker-compose.yml \
# 	-f $(ROOT_DIR)/docker-compose.override.yml

define compose
	docker compose \
		--project-directory $(ROOT_DIR)/$1 \
		-f $(ROOT_DIR)/$1/docker-compose.yml \
		-f $(ROOT_DIR)/docker-compose.override.yml
endef

infra-up:
	$(MAKE) -C infra up

infra-down:
	$(MAKE) -C infra down

infra-clean:
	$(MAKE) -C infra clean

infra-run:
	$(MAKE) -C infra run

stream-up: infra-run $(APPS:%=%-stream-up)

%-stream-up:
	$(call compose,$*) up -d --build qf-app

stream-down: infra-down
	@for app in $(APPS); do \
		$(call compose,$$app) down; \
	done

stream-logs:
	@echo "▶ Streaming logs from all workers"
	@for app in $(APPS); do \
		$(call compose,$$app) logs -f & \
	done; \
	wait

stream-status:
	@for app in $(APPS); do
		echo "===== $$app =====";
		$(call compose,$$app) ps;
	done

downloader-batch-backfill-up:
	$(call compose,downloader) run --rm qf-app worker -- backfill google_drive_fx_1m --start-year 2006 --end-year 2006

downloader-batch-backfill-down:
	$(call compose,downloader) down

downloader-batch-nightly-up:
	$(call compose,downloader) run --rm qf-app worker run

downloader-batch-nightly-down:
	$(call compose,downloader) down


backfill-up: infra-run downloader-batch-backfill-up

nightly-up: infra-run downloader-batch-nightly-up

backfill-down: infra-down downloader-batch-backfill-down

backfill-up: infra-down downloader-batch-nightly-down