#!/bin/sh
set -e

mkdir -p /data

# Substitute environment variables in config template
envsubst < /opt/openfang/config.railway.toml > /data/config.base.toml

# Optional hot-reload overlay: append /data/config.local.toml if present.
# Useful for editing room_triggers, group_policy, allowed_rooms, etc. on the
# volume without a rebuild. A restart is still required — the OpenFang kernel
# only reads the config file on startup.
if [ -f /data/config.local.toml ]; then
  echo "" >> /data/config.base.toml
  echo "# ── Local overrides (/data/config.local.toml) ──" >> /data/config.base.toml
  cat /data/config.local.toml >> /data/config.base.toml
  echo "Appended /data/config.local.toml to config.base.toml"
fi

# Bindings: the repo is source of truth. On every start we overwrite
# /data/bindings.toml from bindings.default.toml so a redeploy always
# matches the committed state. To change routing live without redeploy,
# edit /data/bindings.local.toml on the volume — it is appended after
# bindings.default.toml and overrides matching peer_id rules.
if [ -f /opt/openfang/bindings.default.toml ]; then
  cp /opt/openfang/bindings.default.toml /data/bindings.toml
  echo "Synced /data/bindings.toml from repo (bindings.default.toml)"
fi

if [ -f /data/bindings.local.toml ]; then
  echo "" >> /data/bindings.toml
  echo "# ── Local overrides (/data/bindings.local.toml) ──" >> /data/bindings.toml
  cat /data/bindings.local.toml >> /data/bindings.toml
  echo "Appended local overrides from /data/bindings.local.toml"
fi

if [ -f /data/bindings.toml ]; then
  echo "" >> /data/config.base.toml
  echo "# ── Dynamic bindings (from /data/bindings.toml) ──" >> /data/config.base.toml
  cat /data/bindings.toml >> /data/config.base.toml
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
