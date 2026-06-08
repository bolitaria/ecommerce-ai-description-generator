package middleware

import (
	"log"
	"net/http"
	"time"

	"github.com/google/uuid"
)

// Logging logs each request with a unique trace ID, method, path, remote address, and duration.
func Logging(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		traceID := uuid.New().String()
		r.Header.Set("X-Trace-ID", traceID)
		w.Header().Set("X-Trace-ID", traceID)

		next.ServeHTTP(w, r)

		log.Printf("[%s] %s %s %s %v", traceID, r.Method, r.URL.Path, r.RemoteAddr, time.Since(start))
	})
}