# default args for x86_64
ARG ARCH_SRC_DIR=x86_64
ARG ARCH_GO_IMG=golang:1.9-stretch
ARG ARCH_ALP_IMG=alpine:3.5

# suggested args for arm32:
# ARCH_SRC_DIR=arm32
# ARCH_GO_IMG=arm32v7/golang:1.9-stretch
# ARCH_ALP_IMG=armhf/alpine:3.5 (the core library should be moving from armhf/ to arm32v7/ eventually)
# example: docker build --build-arg ARCH_SRC_DIR=arm32 --build-arg ARCH_GO_IMG=arm32v7/golang:1.9-stretch --build-arg ARCH_ALP_IMG=armhf/alpine:3.5 -t docker-flow-swarm-listener:arm32v7 .

# suggested args for arm64:
# ARCH_SRC_DIR=arm64
# ARCH_GO_IMG=arm64v8/golang:1.9-stretch
# ARCH_ALP_IMG=arm64v8/alpine:3.5
# example: docker build --build-arg ARCH_SRC_DIR=arm64 --build-arg ARCH_GO_IMG=arm64v8/golang:1.9-stretch --build-arg ARCH_ALP_IMG=arm64v8/alpine:3.5 -t docker-flow-swarm-listener:arm64v8 .

FROM monsonnl/qemu-wrap-build-files:latest AS arch_src

ARG ARCH_GO_IMG

FROM ${ARCH_GO_IMG} AS build

ARG ARCH_SRC_DIR

COPY --from=arch_src /cross-build/${ARCH_SRC_DIR}/usr/bin /usr/bin

RUN [ "cross-build-start" ]

COPY . /src
WORKDIR /src
RUN go get -d -v -t
#RUN go test --cover ./...
RUN CGO_ENABLED=0 GOOS=linux go build -v -o docker-flow-swarm-listener
RUN chmod +x /src/docker-flow-swarm-listener

RUN [ "cross-build-end" ]

ARG ARCH_ALP_IMG

FROM ${ARCH_ALP_IMG}
MAINTAINER 	Viktor Farcic <viktor@farcic.com>

COPY --from=build /src/docker-flow-swarm-listener /usr/local/bin/docker-flow-swarm-listener

ENV DF_DOCKER_HOST="unix:///var/run/docker.sock" \
    DF_NOTIFICATION_URL="" \
    DF_INTERVAL="5" \
    DF_RETRY="50" \
    DF_RETRY_INTERVAL="5" \
    DF_NOTIFY_LABEL="com.df.notify"

EXPOSE 8080

CMD ["docker-flow-swarm-listener"]
