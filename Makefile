SHELL := /usr/bin/env bash

CC := gcc
CFLAGS := -Wall -Wextra -Werror -std=c11 -O2

SRC_DIR := src
BIN_DIR := bin
SCRIPTS_DIR := scripts

CHECKSUM_SRC := $(SRC_DIR)/checksum.c
CHECKSUM_BIN := $(BIN_DIR)/checksum

SCRIPTS := \
	$(SCRIPTS_DIR)/admin.sh \
	$(SCRIPTS_DIR)/user_manager.sh \
	$(SCRIPTS_DIR)/group_manager.sh \
	$(SCRIPTS_DIR)/permission_manager.sh \
	$(SCRIPTS_DIR)/provision_departments.sh \
	$(SCRIPTS_DIR)/ssh_access_audit.sh \
	$(SCRIPTS_DIR)/security_monitor.sh \
	$(SCRIPTS_DIR)/log_analyzer.sh

.PHONY: all build clean test check scripts docker-config docker-build up down logs help

all: build

build: $(CHECKSUM_BIN)

$(CHECKSUM_BIN): $(CHECKSUM_SRC)
	@mkdir -p $(BIN_DIR)
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -rf $(BIN_DIR)

test: check

check: scripts docker-config

scripts:
	bash -n $(SCRIPTS)

docker-config:
	docker compose config --quiet

docker-build:
	docker compose build

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f

help:
	@printf '%s\n' \
		'Targets disponibles:' \
		'  make build         Compila bin/checksum desde src/checksum.c' \
		'  make clean         Elimina binarios generados' \
		'  make check         Valida scripts Bash y docker-compose.yml' \
		'  make test          Alias de make check' \
		'  make docker-build  Construye las imagenes Docker' \
		'  make up            Levanta los servicios en segundo plano' \
		'  make down          Detiene los servicios' \
		'  make logs          Muestra logs de Docker Compose' \
		'  make help          Muestra esta ayuda'
