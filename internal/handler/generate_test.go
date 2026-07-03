package handler_test

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/handler"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/service"
)

// mockAIClient implements domain.AIGenerator
type mockAIClient struct{}

func (m *mockAIClient) GenerateDescription(ctx context.Context, productName, features string) (string, error) {
	return "mocked description for " + productName, nil
}

func (m *mockAIClient) TranslateText(ctx context.Context, text, targetLang string) (string, error) {
	return "translated: " + text, nil
}

func (m *mockAIClient) GenerateEmail(ctx context.Context, productName, features string) (string, string, error) {
	return "subj", "body", nil
}

func TestGenerateHandler_Success(t *testing.T) {
	aiSvc := service.NewAIService(&mockAIClient{})
	h := handler.NewGenerateHandler(aiSvc)

	body := `{"product_name":"TestProduct","features":"red,big"}`
	req := httptest.NewRequest(http.MethodPost, "/generate", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rec.Code)
	}
	var resp map[string]string
	json.NewDecoder(rec.Body).Decode(&resp)
	if resp["description"] == "" {
		t.Error("expected a description")
	}
}

func TestGenerateHandler_BadMethod(t *testing.T) {
	aiSvc := service.NewAIService(&mockAIClient{})
	h := handler.NewGenerateHandler(aiSvc)

	req := httptest.NewRequest(http.MethodGet, "/generate", nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusMethodNotAllowed {
		t.Fatalf("expected 405, got %d", rec.Code)
	}
}

func TestGenerateHandler_InvalidJSON(t *testing.T) {
	aiSvc := service.NewAIService(&mockAIClient{})
	h := handler.NewGenerateHandler(aiSvc)

	req := httptest.NewRequest(http.MethodPost, "/generate", bytes.NewBufferString("not json"))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d", rec.Code)
	}
}
