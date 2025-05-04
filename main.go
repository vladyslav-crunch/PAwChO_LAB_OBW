package main

import (
	"fmt"
	"net/http"
	"time"
)

func main() {
	// Create a new router (ServeMux)
	mux := http.NewServeMux()

	// Healthcheck endpoint
	mux.HandleFunc("/healthcheck", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	// Serve static files under "/"
	fileServer := http.FileServer(http.Dir("./static"))
	mux.Handle("/", fileServer)

	// Get current time
	startTime := time.Now().Format("2006-01-02 15:04:05")

	// Log start time and server info
	fmt.Printf("[%s] Starting server on port 8080. Created by Vladyslav Tretiak\n", startTime)

	// Start server
	http.ListenAndServe(":8080", mux)
}
