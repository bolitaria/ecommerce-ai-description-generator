package handler

import (
	"encoding/json"
	"log"
	"net/http"
	"strings"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/service"
)

type EmailHandler struct {
	aiSvc *service.AIService
}

func NewEmailHandler(aiSvc *service.AIService) *EmailHandler {
	return &EmailHandler{aiSvc: aiSvc}
}

func (h *EmailHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
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
	subj, body, err := h.aiSvc.GenerateEmail(r.Context(), req.ProductName, req.Features)
	if err != nil {
		log.Printf("Email generation error: %v", err)
		writeError(w, http.StatusInternalServerError, "email generation failed")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"subject": subj, "body": body})
}