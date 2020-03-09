package main

import (
	"net/http"
	"net/http/httptest"
	"regexp"
	"strconv"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestIndex(t *testing.T) {
	c := map[string]store{
		"memory": &memoryStore{},
		"redis":  createTestRedisStore(),
	}

	for k, v := range c {
		t.Run(k, func(t *testing.T) {
			req := httptest.NewRequest("GET", "/", nil)
			rec := httptest.NewRecorder()

			s := webServer{store: v}
			s.indexHandler(rec, req)

			assert.Equal(t, http.StatusOK, rec.Code)
		})
	}

}

func TestIncrement(t *testing.T) {
	c := map[string]store{
		"memory": &memoryStore{},
		"redis":  createTestRedisStore(),
	}

	for k, v := range c {
		t.Run(k, func(t *testing.T) {
			req := httptest.NewRequest("GET", "/", nil)

			s := webServer{store: v}
			for i := 0; i < 10; i++ {
				rec := httptest.NewRecorder()
				s.incrementHandler(rec, req)

				assert.Equal(t, http.StatusSeeOther, rec.Code)
				assert.Equal(t, []string{"/"}, rec.HeaderMap["Location"])

				rec = httptest.NewRecorder()
				s.indexHandler(rec, req)
				assert.Equal(t, http.StatusOK, rec.Code)
				assert.Equal(t, i+1, findCount(rec.Body.String()))
			}
		})
	}
}

func findCount(body string) int {
	r := regexp.MustCompile("\\d+")
	f := r.FindString(body)
	i, err := strconv.ParseInt(f, 10, 64)
	if err != nil {
		panic(err)
	}

	return int(i)
}
