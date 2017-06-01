FROM alpine:3.5

RUN apk update &&\
    apk add wget ca-certificates make

RUN wget -O /usr/bin/bosh https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-2.0.16-linux-amd64 &&\
    chmod +x /usr/bin/bosh

# Mount the current dir into the repo at this path
WORKDIR /opt/bosh-release
