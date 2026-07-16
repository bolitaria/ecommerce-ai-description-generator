package handler

import (
	"encoding/json"
	"log"
	"net/http"
	"strings"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/service"
)

type TranslateHandler struct {
	aiSvc *service.AIService
}

func NewTranslateHandler(aiSvc *service.AIService) *TranslateHandler {
	return &TranslateHandler{aiSvc: aiSvc}
}

func (h *TranslateHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}
	var req struct {
		Text       string `json:"text"`
		TargetLang string `json:"target_lang"`
	}
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
	trans, err := h.aiSvc.TranslateText(r.Context(), req.Text, req.TargetLang)
	if err != nil {
		log.Printf("Translation error: %v", err)
		writeError(w, http.StatusInternalServerError, "translation failed")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"translated": trans})
}