#!/bin/sh
set -e

SNAPSHOT_URL="https://mainnet-full-snapshots.base.org/$(curl -s https://mainnet-full-snapshots.base.org/latest)"
DATA_DIR="/data"

if [ ! -d "$DATA_DIR/chaindata" ]; then
  echo "Downloading Base snapshot..."
  apk add --no-cache aria2 zstd
  cd /tmp
  aria2c -x16 -s16 -k1M "$SNAPSHOT_URL" -o snap.zst
  tar -I zstd -xf snap.zst -C "$DATA_DIR"
  rm snap.zst
fi

echo "Starting Nethermind..."
exec nethermind "$@"
