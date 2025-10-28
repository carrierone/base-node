#!/bin/sh
set -e

# Generate JWT secret
if [ ! -f /data/jwt.txt ]; then
  openssl rand -hex 32 > /data/jwt.txt
  echo "JWT secret generated"
fi

# Generate P2P private key
if [ ! -f /data/priv.txt ]; then
  openssl rand -hex 32 > /data/priv.txt
  echo "P2P private key generated"
fi

echo "OP-Node setup complete"

# Start op-node with all arguments passed to the script
exec /usr/local/bin/op-node "$@"
