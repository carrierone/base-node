FROM golang:1.23.2-alpine AS builder
RUN apk add --no-cache git
WORKDIR /app
RUN git clone --depth 1 --branch v1.14.3 https://github.com/ethereum-optimism/optimism.git .
RUN cd op-node && go build -o /usr/local/bin/op-node ./cmd

FROM alpine:latest
RUN apk add --no-cache ca-certificates curl openssl
COPY --from=builder /usr/local/bin/op-node /usr/local/bin/op-node
COPY setup-op-node.sh /setup-op-node.sh
RUN chmod +x /usr/local/bin/op-node /setup-op-node.sh
ENTRYPOINT ["/setup-op-node.sh"]
CMD ["op-node"]
