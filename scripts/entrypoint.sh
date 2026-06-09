#!/usr/bin/env bash

set -euo pipefail

cd /app

./scripts/setup_server.sh
./scripts/users.sh cargar-config

exec /usr/sbin/sshd -D
