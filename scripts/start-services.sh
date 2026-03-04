#!/usr/bin/env bash
# Terminal 1 — install deps, start etcd + NATS, then run the Dynamo frontend.
# Run directly (no sourcing needed):
#   bash scripts/start-services.sh

set -euo pipefail

export PATH="/usr/local/bin/etcd:$PATH"

apt-get update -qq
apt-get install -y iproute2

nohup etcd \
  --listen-client-urls http://0.0.0.0:2379 \
  --advertise-client-urls http://0.0.0.0:2379 \
  --data-dir /workspace/etcd-data \
  > /workspace/logs/etcd.log 2>&1 &

nohup nats-server -js -p 4222 -m 8222 \
  --store_dir /workspace/nats-data \
  > /workspace/logs/nats.log 2>&1 &

echo "etcd and NATS started. Starting Dynamo frontend..."

python -m dynamo.frontend --http-host 0.0.0.0 --http-port 8000
