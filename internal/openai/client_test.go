package deepseek_test

import (
	"context"
	"testing"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/deepseek"
)

func TestInterfaceCompliance(t *testing.T) {
	// Ensure NewClient returns an AIClient interface
	var _ deepseek.AIClient = deepseek.NewClient("sk-test", "http://example.com", "test-model")
}

func TestGenerateDescriptionErrorOnBadURL(t *testing.T) {
	client := deepseek.NewClient("sk-test", "http://localhost:1/nonexistent", "test-model")
	_, err := client.GenerateDescription(context.Background(), "test", "test")
	if err == nil {
		t.Error("expected error for bad URL")
	}
}
