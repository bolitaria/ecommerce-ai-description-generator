package handler_test

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/handler"
)

// mockAIClient implements all methods of openai.AIClient for testing.
type mockAIClient struct{}

func (m *mockAIClient) GenerateDescription(ctx context.Context, name, features string) (string, error) {
	return "Mock description for " + name, nil
}

func (m *mockAIClient) TranslateText(ctx context.Context, text, targetLang string) (string, error) {
	return "Translated: " + text, nil
}

func (m *mockAIClient) GenerateEmail(ctx context.Context, name, features string) (string, string, error) {
	return "Mock subject", "Mock body", nil
}

func TestGenerateDescriptionSuccess(t *testing.T) {
	body := map[string]string{"product_name": "Sticker Pack", "features": "Waterproof"}
	jsonBody, _ := json.Marshal(body)
	req := httptest.NewRequest(http.MethodPost, "/generate", bytes.NewReader(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	handler.GenerateDescription(&mockAIClient{})(w, req)

	resp := w.Result()
	if resp.StatusCode != http.StatusOK {
		t.Errorf("expected 200, got %d", resp.StatusCode)
	}

	var out map[string]string
	json.NewDecoder(resp.Body).Decode(&out)
	if out["description"] != "Mock description for Sticker Pack" {
		t.Errorf("unexpected description: %s", out["description"])
	}
}

func TestGenerateDescriptionBadMethod(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/generate", nil)
	w := httptest.NewRecorder()

	handler.GenerateDescription(&mockAIClient{})(w, req)

	resp := w.Result()
	if resp.StatusCode != http.StatusMethodNotAllowed {
		t.Errorf("expected 405, got %d", resp.StatusCode)
	}
}

func TestGenerateDescriptionInvalidJSON(t *testing.T) {
	req := httptest.NewRequest(http.MethodPost, "/generate", bytes.NewReader([]byte("not json")))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	handler.GenerateDescription(&mockAIClient{})(w, req)

	resp := w.Result()
	if resp.StatusCode != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", resp.StatusCode)
	}
}
