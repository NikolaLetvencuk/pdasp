FROM golang:1.21-alpine AS build
WORKDIR /go/src/chaincode
COPY go.mod go.sum ./
RUN go mod download
COPY *.go ./
RUN CGO_ENABLED=0 go build -o /chaincode .

FROM alpine:3.19
COPY --from=build /chaincode /chaincode
EXPOSE 9999
CMD ["/chaincode"]
