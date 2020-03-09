package main

import (
	"github.com/go-redis/redis/v7"
)

type memoryStore struct {
	counter int
}

func (m *memoryStore) Increment() {
	m.counter++
}

func (m *memoryStore) Value() int {
	return m.counter
}

type redisStore struct {
	client *redis.Client
	key    string
}

func newRedisStore(key string, o *redis.Options) *redisStore {
	return &redisStore{
		key:    key,
		client: redis.NewClient(o),
	}
}

func (r *redisStore) Increment() {
	c := r.client.Incr(r.key)
	if err := c.Err(); err != nil {
		panic(err)
	}
}

func (r *redisStore) Value() int {
	c := r.client.Get(r.key)
	err := c.Err()
	if err == redis.Nil {
		return 0
	} else if err != nil {
		panic(err)
	}
	i, err := c.Int()
	if err != nil {
		panic(err)
	}
	return i
}
