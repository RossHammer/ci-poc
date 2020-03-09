package main

import (
	"log"
	"net/http"
	"os"

	"github.com/go-redis/redis/v7"
)

func main() {
	log.Println("Starting server")
	addr, ok := os.LookupEnv("REDIS_ADDR")
	if !ok {
		panic("REDIS_ADDR not set")
	}
	s := webServer{store: newRedisStore("prod", &redis.Options{Addr: addr})}
	http.HandleFunc("/increment", s.incrementHandler)
	http.HandleFunc("/", s.indexHandler)
	log.Fatal(http.ListenAndServe(":8080", nil))
}
