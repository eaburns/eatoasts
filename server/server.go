package server

import (
	"net/http"
	"path"
)

func init() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		http.ServeFile(w, r, path.Join("html/", r.URL.Path))
	})
}
