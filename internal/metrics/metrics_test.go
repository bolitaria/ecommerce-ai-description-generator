package metrics

import (
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestNew_RegistersCustomAndRuntimeMetrics(t *testing.T) {
	m := New("test-service")

	// Drive a request through the middleware so the HTTP vector children exist.
	wrapped := m.HTTPMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))
	wrapped.ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(http.MethodGet, "/test-route", nil))

	// Materialize the AI provider vectors so they appear.
	m.AIProviderRequestsTotal.WithLabelValues("groq", "generate_description", "success").Inc()
	m.AIProviderRequestDuration.WithLabelValues("groq", "generate_description").Observe(0.5)
	m.AIProviderFallbacksTotal.WithLabelValues("groq", "deepseek", "generate_description").Inc()

	h := m.Handler()

	req := httptest.NewRequest(http.MethodGet, "/metrics", nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rec.Code)
	}
	body, _ := io.ReadAll(rec.Body)
	text := string(body)

	// Custom metrics are present.
	for _, want := range []string{
		"http_requests_total",
		"http_request_duration_seconds",
		"http_requests_in_flight",
		"ai_provider_requests_total",
		"ai_provider_request_duration_seconds",
		"ai_provider_fallbacks_total",
	} {
		if !strings.Contains(text, want) {
			t.Errorf("missing metric %q in /metrics output", want)
		}
	}

	// Go runtime collector is present.
	if !strings.Contains(text, "go_goroutines") {
		t.Error("missing go_goroutines (runtime collector)")
	}

	// Service label is applied.
	if !strings.Contains(text, `app="test-service"`) {
		t.Error("missing service label")
	}
}

func TestHTTPMiddleware_CountsRequests(t *testing.T) {
	m := New("test-service")

	mux := http.NewServeMux()
	mux.HandleFunc("/hello", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("hi"))
	})
	mux.HandleFunc("/boom", func(w http.ResponseWriter, r *http.Request) {
		http.Error(w, "err", http.StatusInternalServerError)
	})

	wrapped := m.HTTPMiddleware(mux)

	// Two OK, one 500.
	for i := 0; i < 2; i++ {
		rec := httptest.NewRecorder()
		wrapped.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/hello", nil))
		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200, got %d", rec.Code)
		}
	}
	rec := httptest.NewRecorder()
	wrapped.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/boom", nil))
	if rec.Code != http.StatusInternalServerError {
		t.Fatalf("expected 500, got %d", rec.Code)
	}

	// Verify counters via the exposition endpoint.
	h := m.Handler()
	req := httptest.NewRequest(http.MethodGet, "/metrics", nil)
	rec2 := httptest.NewRecorder()
	h.ServeHTTP(rec2, req)

	body, _ := io.ReadAll(rec2.Body)
	text := string(body)

	if !strings.Contains(text, `http_requests_total{method="GET",path="/hello",app="test-service",status="200"} 2`) {
		t.Errorf("expected /hello counter == 2, got:\n%s", grep(text, "http_requests_total"))
	}
	if !strings.Contains(text, `http_requests_total{method="GET",path="/boom",app="test-service",status="500"} 1`) {
		t.Errorf("expected /boom counter == 1, got:\n%s", grep(text, "http_requests_total"))
	}
}

// grep returns only lines containing needle, for compact failure messages.
func grep(text, needle string) string {
	var out strings.Builder
	for _, line := range strings.Split(text, "\n") {
		if strings.Contains(line, needle) {
			out.WriteString(line)
			out.WriteString("\n")
		}
	}
	return out.String()
}
