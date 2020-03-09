package main

import (
	"fmt"
	"net/http"
)

func (s *webServer) indexHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Add("Content-Type", "text/html")
	fmt.Fprintf(w, "<p>Counter: %d</p><p><a href=\"/increment\">increment</a></p>", s.store.Value())
}

func (s *webServer) incrementHandler(w http.ResponseWriter, r *http.Request) {
	s.store.Increment()
	w.Header().Add("Location", "/")
	w.WriteHeader(http.StatusSeeOther)
}

type store interface {
	Increment()
	Value() int
}

type webServer struct {
	store store
}
