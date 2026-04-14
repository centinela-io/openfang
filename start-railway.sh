#!/bin/sh
set -e

mkdir -p /data

# Substitute environment variables in config template
envsubst < /opt/openfang/config.railway.toml > /data/config.toml

# Copy custom agents on first run or when updated
if [ -d /opt/openfang/agents ]; then
  mkdir -p /data/agents
  cp -r /opt/openfang/agents/* /data/agents/ 2>/dev/null || true
fi

# Initialize OpenFang if first run
if [ ! -f /data/openfang.db ]; then
  echo "First run — initializing OpenFang..."
  OPENFANG_HOME=/data openfang init --config /data/config.toml 2>/dev/null || true
fi

echo "Starting OpenFang Agent OS..."
exec openfang start --config /data/config.toml
