#!/bin/sh
set -e
echo "Installing dependencies..."
apt update -qq && apt install -y -qq curl aria2 zstd > /dev/null
SNAPSHOT_URL="https://mainnet-full-snapshots.base.org/$(curl -s https://mainnet-full-snapshots.base.org/latest)"
DATA_DIR="/data"
if [ ! -d "$DATA_DIR/chaindata" ]; then
  echo "Downloading Base snapshot: $SNAPSHOT_URL"
  cd /tmp
  aria2c -x16 -s16 -k1M "$SNAPSHOT_URL" -o snap.zst
  echo "Extracting..."
  tar -I zstd -xf snap.zst -C "$DATA_DIR"
  rm -f snap.zst
  echo "Snapshot ready."
else
  echo "Snapshot exists. Skipping."
fi
echo "Starting Nethermind..."
exec nethermind "$@"
