package aiservice

import (
	"encoding/json"
	"log/slog"
	"net/http"
	"strings"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/domain"
)

// writeJSON writes a JSON response with the given status code.
func writeJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

// writeError writes a JSON error response.
func writeError(w http.ResponseWriter, status int, msg string) {
	writeJSON(w, status, map[string]string{"error": msg})
}

// DescriptionHandler handles POST /v1/descriptions.
type DescriptionHandler struct {
	ai     domain.AIGenerator
	logger *slog.Logger
}

func NewDescriptionHandler(ai domain.AIGenerator, logger *slog.Logger) *DescriptionHandler {
	return &DescriptionHandler{ai: ai, logger: logger}
}

type descriptionRequest struct {
	ProductName string `json:"product_name"`
	Features    string `json:"features"`
}

type descriptionResponse struct {
	Description string `json:"description"`
	Provider    string `json:"provider,omitempty"`
}

func (h *DescriptionHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}
	var req descriptionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON")
		return
	}
	req.ProductName = strings.TrimSpace(req.ProductName)
	req.Features = strings.TrimSpace(req.Features)
	if req.ProductName == "" || req.Features == "" {
		writeError(w, http.StatusBadRequest, "product_name and features required")
		return
	}
	desc, err := h.ai.GenerateDescription(r.Context(), req.ProductName, req.Features)
	if err != nil {
		h.logger.Error("generate_description failed", "error", err)
		writeError(w, http.StatusInternalServerError, "generation failed")
		return
	}
	writeJSON(w, http.StatusOK, descriptionResponse{Description: desc})
}

// TranslateHandler handles POST /v1/translations.
type TranslateHandler struct {
	ai     domain.AIGenerator
	logger *slog.Logger
}

func NewTranslateHandler(ai domain.AIGenerator, logger *slog.Logger) *TranslateHandler {
	return &TranslateHandler{ai: ai, logger: logger}
}

type translateRequest struct {
	Text       string `json:"text"`
	TargetLang string `json:"target_lang"`
}

type translateResponse struct {
	Translated string `json:"translated"`
}

func (h *TranslateHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}
	var req translateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON")
		return
	}
	req.Text = strings.TrimSpace(req.Text)
	req.TargetLang = strings.TrimSpace(req.TargetLang)
	if req.Text == "" || req.TargetLang == "" {
		writeError(w, http.StatusBadRequest, "text and target_lang required")
		return
	}
	trans, err := h.ai.TranslateText(r.Context(), req.Text, req.TargetLang)
	if err != nil {
		h.logger.Error("translate failed", "error", err)
		writeError(w, http.StatusInternalServerError, "translation failed")
		return
	}
	writeJSON(w, http.StatusOK, translateResponse{Translated: trans})
}

// EmailHandler handles POST /v1/emails.
type EmailHandler struct {
	ai     domain.AIGenerator
	logger *slog.Logger
}

func NewEmailHandler(ai domain.AIGenerator, logger *slog.Logger) *EmailHandler {
	return &EmailHandler{ai: ai, logger: logger}
}

type emailRequest struct {
	ProductName string `json:"product_name"`
	Features    string `json:"features"`
}

type emailResponse struct {
	Subject string `json:"subject"`
	Body    string `json:"body"`
}

func (h *EmailHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}
	var req emailRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON")
		return
	}
	req.ProductName = strings.TrimSpace(req.ProductName)
	req.Features = strings.TrimSpace(req.Features)
	if req.ProductName == "" || req.Features == "" {
		writeError(w, http.StatusBadRequest, "product_name and features required")
		return
	}
	subj, body, err := h.ai.GenerateEmail(r.Context(), req.ProductName, req.Features)
	if err != nil {
		h.logger.Error("generate_email failed", "error", err)
		writeError(w, http.StatusInternalServerError, "email generation failed")
		return
	}
	writeJSON(w, http.StatusOK, emailResponse{Subject: subj, Body: body})
}

// HealthHandler handles GET /healthz (liveness).
func HealthHandler() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
	}
}

// ReadyHandler handles GET /readyz (readiness).
func ReadyHandler() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]string{"status": "ready"})
	}
}
