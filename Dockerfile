# Copyright 2019 Hammerspace

FROM golang:1.10-alpine3.8
RUN apk add --no-cache git make
WORKDIR /go/src/github.com/hammerspace/hammerspace-csi-plugin/
ADD . ./
RUN go get golang.org/x/vgo
RUN make clean compile

FROM alpine:3.8
RUN apk add --no-cache nfs-utils qemu-img
WORKDIR /bin/
COPY --from=0 /go/src/github.com/hammerspace/hammerspace-csi-plugin/bin/hs-csi-plugin .
ENTRYPOINT ["/bin/hs-csi-plugin"]
