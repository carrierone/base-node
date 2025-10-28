# Multi-stage build: compile op-node from source for Alpine (musl libc)
FROM golang:1.23.2-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git make gcc musl-dev linux-headers

# Set working directory
WORKDIR /build

# Clone specific version of Optimism repository (cached if version doesn't change)
ARG OP_NODE_VERSION=v1.14.3
RUN git clone --depth 1 --branch ${OP_NODE_VERSION} https://github.com/ethereum-optimism/optimism.git .

# Build op-node with static linking for Alpine
WORKDIR /build/op-node
RUN go build -ldflags="-s -w" -o /usr/local/bin/op-node ./cmd

# Final minimal runtime image
FROM alpine:latest

# Install runtime dependencies only
RUN apk add --no-cache ca-certificates curl openssl

# Copy compiled binary from builder stage
COPY --from=builder /usr/local/bin/op-node /usr/local/bin/op-node

# Copy setup script
COPY setup-op-node.sh /setup-op-node.sh

# Set permissions
RUN chmod +x /usr/local/bin/op-node /setup-op-node.sh

ENTRYPOINT ["/setup-op-node.sh"]
CMD ["op-node"]
