#!/bin/sh
set -e

mkdir -p /data

# Substitute environment variables in config template
envsubst < /opt/openfang/config.railway.toml > /data/config.base.toml

# Seed default bindings on first run
if [ ! -f /data/bindings.toml ] && [ -f /opt/openfang/bindings.default.toml ]; then
  cp /opt/openfang/bindings.default.toml /data/bindings.toml
  echo "Seeded default bindings to /data/bindings.toml"
fi

# If a custom bindings override exists on the volume, append it
# This allows changing bindings without rebuilding
if [ -f /data/bindings.toml ]; then
  echo "" >> /data/config.base.toml
  echo "# ── Dynamic bindings (from /data/bindings.toml) ──" >> /data/config.base.toml
  cat /data/bindings.toml >> /data/config.base.toml
  echo "Using custom bindings from /data/bindings.toml"
fi

cp /data/config.base.toml /data/config.toml

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
