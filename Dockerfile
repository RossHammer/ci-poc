FROM golang:alpine as build

WORKDIR /build
COPY . .
RUN go build -o /service ./service

FROM alpine

COPY --from=build /service .
CMD ./service
