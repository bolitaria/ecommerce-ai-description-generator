package config

import (
	"os"
	"testing"
)

func TestLoad_DefaultsForAIService(t *testing.T) {
	// Ensure the new env vars are unset for this test.
	os.Unsetenv("AI_SERVICE_URL")
	os.Unsetenv("INTERNAL_API_TOKEN")

	cfg := Load()

	if cfg.AIServiceURL != "http://localhost:8081" {
		t.Errorf("expected default AIServiceURL http://localhost:8081, got %q", cfg.AIServiceURL)
	}
	if cfg.InternalAPIToken != "" {
		t.Errorf("expected empty InternalAPIToken by default, got %q", cfg.InternalAPIToken)
	}
}

func TestLoad_AIServiceOverrides(t *testing.T) {
	t.Setenv("AI_SERVICE_URL", "http://ai-service:9999")
	t.Setenv("INTERNAL_API_TOKEN", "test-token-abc123")

	cfg := Load()

	if cfg.AIServiceURL != "http://ai-service:9999" {
		t.Errorf("AIServiceURL override failed: got %q", cfg.AIServiceURL)
	}
	if cfg.InternalAPIToken != "test-token-abc123" {
		t.Errorf("InternalAPIToken override failed: got %q", cfg.InternalAPIToken)
	}
}
