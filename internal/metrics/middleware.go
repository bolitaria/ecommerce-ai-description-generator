package metrics

import (
	"net/http"
	"strconv"
	"time"
)

// statusRecorder wraps http.ResponseWriter to capture the status code.
type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (r *statusRecorder) WriteHeader(code int) {
	r.status = code
	r.ResponseWriter.WriteHeader(code)
}

// HTTPMiddleware instruments HTTP handlers with RED metrics:
// Rate (requests total), Errors (requests by status), Duration (histogram).
//
// The route label is populated from the request's matched pattern when
// available (Go 1.22+ http.ServeMux), falling back to a sanitised path.
func (m *Metrics) HTTPMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		m.HTTPRequestsInFlight.Inc()
		defer m.HTTPRequestsInFlight.Dec()

		rec := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
		next.ServeHTTP(rec, r)

		route := routeLabel(r)
		status := strconv.Itoa(rec.status)

		m.HTTPRequestsTotal.WithLabelValues(r.Method, route, status).Inc()
		m.HTTPRequestDuration.WithLabelValues(r.Method, route).Observe(time.Since(start).Seconds())
	})
}

// routeLabel returns the matched pattern when available, otherwise the path.
// This keeps cardinality low even with path parameters.
func routeLabel(r *http.Request) string {
	if r.Pattern != "" {
		return r.Pattern
	}
	if p := r.URL.Path; p != "" {
		return p
	}
	return "/"
}
