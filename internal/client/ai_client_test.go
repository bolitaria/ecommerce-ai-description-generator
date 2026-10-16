package client

import (
	"context"
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/tracing"
)

func newTestLogger() *slog.Logger {
	return slog.New(slog.NewTextHandler(io.Discard, nil))
}

func TestAIClient_GenerateDescription(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/v1/descriptions" {
			t.Errorf("unexpected path: %s", r.URL.Path)
		}
		if r.Method != http.MethodPost {
			t.Errorf("unexpected method: %s", r.Method)
		}
		if got := r.Header.Get(headerInternalToken); got != "secret-token" {
			t.Errorf("missing/wrong internal token: %q", got)
		}
		var req map[string]string
		_ = json.NewDecoder(r.Body).Decode(&req)
		if req["product_name"] != "Widget" {
			t.Errorf("product_name not forwarded: %v", req)
		}
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]string{"description": "A great widget."})
	}))
	defer srv.Close()

	c := New(srv.URL, "secret-token", newTestLogger())
	got, err := c.GenerateDescription(context.Background(), "Widget", "shiny")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != "A great widget." {
		t.Errorf("expected description, got %q", got)
	}
}

func TestAIClient_TranslateAndEmail(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		switch r.URL.Path {
		case "/v1/translations":
			_ = json.NewEncoder(w).Encode(map[string]string{"translated": "hello"})
		case "/v1/emails":
			_ = json.NewEncoder(w).Encode(map[string]string{"subject": "Hi", "body": "Body"})
		default:
			http.NotFound(w, r)
		}
	}))
	defer srv.Close()

	c := New(srv.URL, "", newTestLogger())

	trans, err := c.TranslateText(context.Background(), "hola", "en")
	if err != nil {
		t.Fatalf("translate error: %v", err)
	}
	if trans != "hello" {
		t.Errorf("expected hello, got %q", trans)
	}

	subj, body, err := c.GenerateEmail(context.Background(), "P", "F")
	if err != nil {
		t.Fatalf("email error: %v", err)
	}
	if subj != "Hi" || body != "Body" {
		t.Errorf("unexpected email: subj=%q body=%q", subj, body)
	}
}

func TestAIClient_RetriesOn500(t *testing.T) {
	var attempts int
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		attempts++
		if attempts < 3 {
			http.Error(w, "boom", http.StatusInternalServerError)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]string{"description": "ok after retry"})
	}))
	defer srv.Close()

	c := New(srv.URL, "", newTestLogger())
	got, err := c.GenerateDescription(context.Background(), "P", "F")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != "ok after retry" {
		t.Errorf("expected ok, got %q", got)
	}
	if attempts != 3 {
		t.Errorf("expected 3 attempts, got %d", attempts)
	}
}

func TestAIClient_DoesNotRetryOn400(t *testing.T) {
	var attempts int
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		attempts++
		http.Error(w, "bad request", http.StatusBadRequest)
	}))
	defer srv.Close()

	c := New(srv.URL, "", newTestLogger())
	_, err := c.GenerateDescription(context.Background(), "P", "F")
	if err == nil {
		t.Fatal("expected error, got nil")
	}
	if attempts != 1 {
		t.Errorf("expected 1 attempt for 400, got %d", attempts)
	}
}

func TestAIClient_PropagatesTraceID(t *testing.T) {
	var received string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		received = r.Header.Get(headerTraceID)
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]string{"description": "x"})
	}))
	defer srv.Close()

	ctx := tracing.WithTraceID(context.Background(), "trace-abc-123")
	c := New(srv.URL, "", newTestLogger())
	_, _ = c.GenerateDescription(ctx, "P", "F")

	if received != "trace-abc-123" {
		t.Errorf("expected trace-abc-123, got %q", received)
	}
}

func TestAIClient_HealthCheck(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/healthz" {
			t.Errorf("unexpected path: %s", r.URL.Path)
		}
		w.WriteHeader(http.StatusOK)
	}))
	defer srv.Close()

	c := New(srv.URL, "", newTestLogger())
	if err := c.HealthCheck(context.Background()); err != nil {
		t.Errorf("healthcheck failed: %v", err)
	}
}
