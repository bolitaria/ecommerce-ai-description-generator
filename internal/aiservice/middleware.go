package aiservice

import (
	"log/slog"
	"net/http"
	"time"

	"github.com/google/uuid"
)

// TraceID middleware ensures every request has an X-Trace-ID header,
// either propagated from the caller or newly generated.
func TraceID(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		traceID := r.Header.Get("X-Trace-ID")
		if traceID == "" {
			traceID = uuid.New().String()
		}
		r.Header.Set("X-Trace-ID", traceID)
		w.Header().Set("X-Trace-ID", traceID)
		next.ServeHTTP(w, r)
	})
}

// InternalAuth middleware validates the X-Internal-Token header against
// the configured secret. If secret is empty (e.g. local dev without auth),
// the middleware warns once and allows all traffic.
func InternalAuth(secret string, logger *slog.Logger) func(http.Handler) http.Handler {
	if secret == "" {
		logger.Warn("INTERNAL_API_TOKEN is empty — internal auth is DISABLED")
	}
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Health endpoints bypass auth so orchestrators can probe.
			if r.URL.Path == "/healthz" || r.URL.Path == "/readyz" {
				next.ServeHTTP(w, r)
				return
			}
			if secret != "" {
				token := r.Header.Get("X-Internal-Token")
				if token != secret {
					logger.Warn("internal auth rejected",
						"path", r.URL.Path,
						"remote", r.RemoteAddr,
						"trace_id", r.Header.Get("X-Trace-ID"),
					)
					writeError(w, http.StatusUnauthorized, "unauthorized")
					return
				}
			}
			next.ServeHTTP(w, r)
		})
	}
}

// RequestLogger logs each request with trace ID, method, path, and duration.
func RequestLogger(logger *slog.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()
			next.ServeHTTP(w, r)
			logger.Info("http",
				"method", r.Method,
				"path", r.URL.Path,
				"remote", r.RemoteAddr,
				"duration_ms", time.Since(start).Milliseconds(),
				"trace_id", r.Header.Get("X-Trace-ID"),
			)
		})
	}
}

// Recovery middleware catches panics and returns 500.
func Recovery(logger *slog.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			defer func() {
				if err := recover(); err != nil {
					logger.Error("panic recovered",
						"error", err,
						"path", r.URL.Path,
						"trace_id", r.Header.Get("X-Trace-ID"),
					)
					writeError(w, http.StatusInternalServerError, "internal server error")
				}
			}()
			next.ServeHTTP(w, r)
		})
	}
}
