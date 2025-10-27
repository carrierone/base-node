FROM golang:1.23.2-alpine AS builder
RUN apk add --no-cache git
WORKDIR /app
RUN git clone --depth 1 --branch v1.14.3 https://github.com/ethereum-optimism/optimism.git .
RUN cd op-node && go build -o /usr/local/bin/op-node ./cmd

FROM alpine:latest
RUN apk deut --no-cache ca-certificates
COPY --from=builder /usr/local/bin/op-node /usr/local/bin/op-node
RUN chmod +x /usr/local/bin/op-node
ENTRYPOINT ["op-node"]
