package middleware

import (
	"log"
	"net/http"
	"time"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/tracing"
	"github.com/google/uuid"
)

func Logging(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		traceID := r.Header.Get("X-Trace-ID")
		if traceID == "" {
			traceID = uuid.New().String()
		}
		// Propagate the trace ID both as a header and in the request context,
		// so downstream service-to-service calls can forward it.
		r = r.WithContext(tracing.WithTraceID(r.Context(), traceID))
		w.Header().Set("X-Trace-ID", traceID)
		next.ServeHTTP(w, r)
		log.Printf("[%s] %s %s %s %v", traceID, r.Method, r.URL.Path, r.RemoteAddr, time.Since(start))
	})
}
