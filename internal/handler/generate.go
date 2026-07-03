package handler

import (
	"encoding/json"
	"log"
	"net/http"
	"strings"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/service"
)

type GenerateHandler struct {
	aiSvc *service.AIService
}

func NewGenerateHandler(aiSvc *service.AIService) *GenerateHandler {
	return &GenerateHandler{aiSvc: aiSvc}
}

func (h *GenerateHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}
	var req struct {
		ProductName string `json:"product_name"`
		Features    string `json:"features"`
	}
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
	desc, err := h.aiSvc.GenerateDescription(r.Context(), req.ProductName, req.Features)
	if err != nil {
		log.Printf("AI generation error: %v", err)   // <-- AÑADIDO
		writeError(w, http.StatusInternalServerError, "generation failed")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"description": desc})
}
