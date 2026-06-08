package handler

import (
	"encoding/json"
	"log"
	"net/http"
	"strings"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/openai"
)

type emailRequest struct {
	ProductName string `json:"product_name"`
	Features    string `json:"features"`
}
type emailResponse struct {
	Subject string `json:"subject"`
	Body    string `json:"body"`
}

func GenerateEmail(ai openai.AIClient) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}
		var req emailRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}
		req.ProductName = strings.TrimSpace(req.ProductName)
		req.Features = strings.TrimSpace(req.Features)
		if req.ProductName == "" || req.Features == "" {
			http.Error(w, "product_name and features required", http.StatusBadRequest)
			return
		}
		subject, body, err := ai.GenerateEmail(r.Context(), req.ProductName, req.Features)
		if err != nil {
			log.Printf("Email generation error: %v", err)
			http.Error(w, "Email generation failed", http.StatusInternalServerError)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(emailResponse{Subject: subject, Body: body})
	}
}
