#!/bin/sh
set -e

# Generate JWT if not exists
if [ ! -f /data/jwt.txt ]; then
  openssl rand -hex 32 > /data/jwt.txt
  echo "JWT secret generated for Nethermind"
fi

# Check and install dependencies if needed (fallback for network issues during build)
if ! command -v aria2c >/dev/null 2>&1 || ! command -v zstd >/dev/null 2>&1; then
  echo "Installing snapshot dependencies..."
  apt-get update -qq && apt-get install -y -qq curl aria2 zstd 2>/dev/null || {
    echo "Warning: Failed to install dependencies, snapshot download may fail"
  }
fi

# Dependencies should be installed in the Dockerfile, but we handle runtime fallback
SNAPSHOT_URL="https://mainnet-full-snapshots.base.org/$(curl -s https://mainnet-full-snapshots.base.org/latest)"
DATA_DIR="/data"

if [ ! -d "$DATA_DIR/chaindata" ]; then
  echo "========================================"
  echo "Downloading Base snapshot from: $SNAPSHOT_URL"
  echo "This may take 30 minutes to 2 hours depending on network speed"
  echo "========================================"
  cd /tmp

  # Download with progress indicators
  # -x16 = 16 connections, -s16 = 16 splits per file, -k1M = 1MB pieces
  # --console-log-level=notice = show progress in console
  # --summary-interval=10 = update progress every 10 seconds
  aria2c \
    -x16 -s16 -k1M \
    --console-log-level=notice \
    --summary-interval=10 \
    --download-result=full \
    --file-allocation=none \
    "$SNAPSHOT_URL" \
    -o snap.zst || {
    echo "========================================"
    echo "Error: Failed to download snapshot"
    echo "Starting Nethermind without snapshot (will sync from genesis)..."
    echo "========================================"
    exec nethermind "$@"
  }

  echo "========================================"
  echo "Download complete! Extracting snapshot..."
  echo "This may take 10-20 minutes"
  echo "========================================"

  # Extract with progress (zstd shows progress by default to stderr)
  tar -I "zstd -d -v" -xf snap.zst -C "$DATA_DIR" || {
    echo "========================================"
    echo "Error: Failed to extract snapshot"
    echo "Starting Nethermind without snapshot (will sync from genesis)..."
    echo "========================================"
    rm -f snap.zst
    exec nethermind "$@"
  }

  rm -f snap.zst
  echo "========================================"
  echo "Snapshot ready! Starting Nethermind..."
  echo "========================================"
else
  echo "========================================"
  echo "Snapshot already exists at $DATA_DIR/chaindata"
  echo "Skipping download. Starting Nethermind..."
  echo "========================================"
fi

echo "Starting Nethermind..."
exec nethermind "$@"
