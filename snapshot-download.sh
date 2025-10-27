#!/bin/sh
set -e

# Generate JWT if not exists
if [ ! -f /data/jwt.txt ]; then
  openssl rand -hex 32 > /data/jwt.txt
  echo "JWT secret generated for Nethermind"
fi

# Install deps
apt update -qq && apt install -y -qq curl aria2 zstd > /dev/null

SNAPSHOT_URL="https://mainnet-full-snapshots.base.org/$(curl -s https://mainnet-full-snapshots.base.org/latest)"
DATA_DIR="/data"

if [ ! -d "$DATA_DIR/chaindata" ]; then
  echo "Downloading Base snapshot..."
  cd /tmp
  aria2c -x16 -s16 -k1M "$SNAPSHOT_URL" -o snap.zst
  tar -I zstd -xf snap.zst -C "$DATA_DIR"
  rm -f snap.zst
  echo "Snapshot ready."
else
  echo "Snapshot exists."
fi

echo "Starting Nethermind..."
exec nethermind "$@"
