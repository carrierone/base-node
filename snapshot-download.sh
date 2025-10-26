#!/bin/bash
set -e
SNAPSHOT_URL="https://mainnet-full-snapshots.base.org/$(curl -s https://mainnet-full-snapshots.base.org/latest)"
DATA_DIR="/data"
if [ ! -d "$DATA_DIR/chaindata" ]; then
  echo "Downloading Base snapshot with aria2c..."
  apk add --no-cache aria2 zstd
  cd /tmp
  aria2c -x 16 -s 16 -k 1M "$SNAPSHOT_URL" -o base-geth-full.zst
  tar -I zstd -xvf base-geth-full.zst -C "$DATA_DIR"
  rm base-geth-full.zst
fi
exec "$@"
