# Build Notes

## Docker Build Optimization

This setup uses a multi-stage build strategy with Docker BuildKit for optimal caching and rebuild performance.

### Build Strategy

#### base-op-node (Dockerfile)
- **Stage 1 (Builder):** Compiles op-node from source in golang:alpine
  - Clones specific Optimism version (cached by git tag)
  - Cross-compiles for Alpine musl libc
  - Strips debug symbols for smaller binary (-ldflags="-s -w")

- **Stage 2 (Runtime):** Minimal Alpine image
  - Only runtime dependencies (ca-certificates, curl, openssl)
  - Copies compiled binary from builder stage
  - Final image size: ~50MB vs 1GB+ with build tools

#### base-execution (Dockerfile.nethermind)
- Based on official nethermindeth/nethermind:latest
- Installs snapshot download tools (aria2, zstd) once during build
- No runtime package installation

### Build Caching

Docker BuildKit provides intelligent layer caching:

1. **Base image layers:** Cached unless base image changes
2. **Dependency installation:** Cached unless package list changes
3. **Source code download:** Cached unless version tag changes
4. **Compilation:** Only rebuilds if source code changes

### Initial Build vs Rebuild

**First build (no cache):**
- Downloads all base images
- Clones Optimism repo (~100MB)
- Compiles op-node (~5-10 minutes)
- Total: ~15 minutes

**Subsequent builds (with cache):**
- Uses cached layers
- Only rebuilds changed layers
- Typical rebuild: ~30 seconds
- Version bump rebuild: ~5-10 minutes (recompile only)

### Building

```bash
# Enable BuildKit (optional, build.sh does this automatically)
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Build all services
./build.sh

# Or build with docker-compose
docker-compose build

# Build specific service
docker-compose build base-op-node
docker-compose build base-execution

# Force rebuild without cache (rarely needed)
docker-compose build --no-cache base-op-node

# Change op-node version
docker-compose build --build-arg OP_NODE_VERSION=v1.15.0 base-op-node
```

### Portainer Deployment

When deploying to Portainer:

1. **Stack deployment:** Upload docker-compose.yml
2. **Automatic builds:** Portainer will build images on first deploy
3. **Updates:** Pull from git repo and rebuild stack
4. **Version changes:** Edit build args in Portainer stack editor

### Size Optimization

Current image sizes:
- `base-op-node:latest` - ~50MB (Alpine + compiled binary)
- `base-execution:latest` - ~300MB (Nethermind + tools)

Optimizations applied:
- Multi-stage builds (no build tools in final image)
- Alpine Linux where possible
- Static linking with symbol stripping
- Minimal runtime dependencies
- Clean apt/apk cache

### Troubleshooting

**Problem:** Builds are slow
- **Solution:** Ensure BuildKit is enabled (check DOCKER_BUILDKIT=1)

**Problem:** Binary not found or permission denied
- **Solution:** Check COPY --from=builder step and chmod commands

**Problem:** Binary segfaults or library errors
- **Solution:** Ensure musl-dev is in builder dependencies

**Problem:** Cache not being used
- **Solution:** Check .dockerignore excludes changing files like logs
