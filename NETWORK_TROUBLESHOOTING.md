# Network Troubleshooting Guide

## Build Failure: Connection Timeouts

If you're seeing errors like:
```
E: Failed to fetch http://archive.ubuntu.com/...
E: Connection timed out
```

This indicates network connectivity issues from your Docker build environment to Ubuntu package repositories.

## Solutions

### 1. Check Docker Network Configuration

Test if the Docker build can reach the internet:

```bash
# Test from running container
docker run --rm nethermindeth/nethermind:latest apt-get update

# Test DNS resolution
docker run --rm nethermindeth/nethermind:latest ping -c 3 archive.ubuntu.com
```

### 2. Use Alternative Dockerfile

If network issues persist during build, use the minimal version:

```bash
# Edit docker-compose.yml to use minimal Dockerfile
sed -i 's/dockerfile: Dockerfile.nethermind/dockerfile: Dockerfile.nethermind.minimal/' docker-compose.yml

# Rebuild
docker-compose build base-execution
```

The minimal version installs dependencies at runtime instead of build time.

### 3. Configure Docker to Use Different DNS

Edit `/etc/docker/daemon.json`:

```json
{
  "dns": ["8.8.8.8", "8.8.4.4", "1.1.1.1"]
}
```

Then restart Docker:
```bash
sudo systemctl restart docker
```

### 4. Use HTTP Proxy (if behind corporate firewall)

Edit `docker-compose.yml` and add build args:

```yaml
services:
  base-execution:
    build:
      context: .
      dockerfile: Dockerfile.nethermind
      args:
        http_proxy: http://your-proxy:port
        https_proxy: http://your-proxy:port
```

### 5. Pre-build Images Locally

If Portainer server has network restrictions, build locally and push:

```bash
# Build locally
cd base-node
docker-compose build

# Tag for registry
docker tag base-execution:latest your-registry/base-execution:latest
docker tag base-op-node:latest your-registry/base-op-node:latest

# Push to registry
docker push your-registry/base-execution:latest
docker push your-registry/base-op-node:latest

# Update docker-compose.yml to use registry images
```

### 6. Check Portainer Server Network

On the Portainer server, verify connectivity:

```bash
# Test Ubuntu repos
curl -I http://archive.ubuntu.com/ubuntu/

# Test if firewall is blocking
sudo iptables -L -n | grep DROP

# Check if HTTP/HTTPS ports are accessible
telnet archive.ubuntu.com 80
telnet archive.ubuntu.com 443
```

### 7. Use Retry Logic (Already Implemented)

The updated `Dockerfile.nethermind` now includes automatic retry logic with 5 attempts and 5-second delays.

### 8. Build with Docker BuildKit Cache Mounts

BuildKit can cache apt packages between builds:

```dockerfile
# Example: Add to Dockerfile.nethermind
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update && apt-get install -y aria2 zstd curl
```

## Quick Fix: Skip Snapshot Download

If all else fails, you can start Nethermind without the snapshot (it will sync from genesis):

```bash
# Temporarily comment out snapshot download in docker-compose.yml
# The node will sync from scratch (takes longer but works)
```

## Recommended Approach for Portainer

1. **First try:** Use the updated `Dockerfile.nethermind` with retry logic (already done)
2. **If that fails:** Use `Dockerfile.nethermind.minimal` (runtime installation)
3. **If that fails:** Build images on a machine with better network access and push to a registry
4. **Last resort:** Configure HTTP proxy or alternative Ubuntu mirrors

## Testing Network Access

Create a test container to verify connectivity:

```bash
docker run --rm -it nethermindeth/nethermind:latest bash

# Inside container:
apt-get update
apt-get install -y curl
curl -I http://archive.ubuntu.com/ubuntu/
ping -c 3 8.8.8.8
```

If this fails, the issue is with Docker networking on the host, not the Dockerfile.
