package main

import (
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/go-redis/redis/v7"

	"github.com/stretchr/testify/assert"
)

func TestMemory(t *testing.T) {
	s := memoryStore{}

	assert.Equal(t, 0, s.Value())
	s.Increment()
	s.Increment()
	s.Increment()
	assert.Equal(t, 3, s.Value())
}

func createTestRedisStore() *redisStore {
	addr, ok := os.LookupEnv("REDIS_ADDR")
	if !ok {
		panic("REDIS_ADDR not set")
	}
	s := newRedisStore(fmt.Sprintf("test_%s", time.Now()), &redis.Options{
		Addr: addr,
	})
	return s
}

func TestRedis(t *testing.T) {
	s := createTestRedisStore()

	assert.Equal(t, 0, s.Value())
	s.Increment()
	s.Increment()
	s.Increment()
	assert.Equal(t, 3, s.Value())
}
