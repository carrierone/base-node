# Use a lightweight base
FROM alpine:latest

# Install runtime deps (none needed for nethermind, but keep for consistency)
RUN apk add --no-cache ca-certificates

# Copy the snapshot script
COPY snapshot-download.sh /snapshot-download.sh
RUN chmod +x /snapshot-download.sh

# Keep op-node binary (if you still use it in base-op-node)
COPY op-node /usr/local/bin/op-node
RUN chmod +x /usr/local/bin/op-node

# Default entrypoint (only used by base-op-node)
ENTRYPOINT ["op-node"]
