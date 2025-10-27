FROM alpine:latest
RUN apk add --no-cache ca-certificates
COPY op-node /usr/local/bin/op-node
RUN chmod +x /usr/local/bin/op-node
ENTRYPOINT ["op-node"]
