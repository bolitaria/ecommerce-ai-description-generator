package handler

import (
	"encoding/json"
	"log"
	"net/http"
	"strings"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/openai"
)

type generateRequest struct {
	ProductName string `json:"product_name"`
	Features    string `json:"features"`
}

type generateResponse struct {
	Description string `json:"description"`
}

// GenerateDescription returns an HTTP handler that uses the given AIClient
// to generate product descriptions.
func GenerateDescription(ai openai.AIClient) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		var req generateRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "Invalid JSON body", http.StatusBadRequest)
			return
		}

		// Sanitize and validate inputs
		req.ProductName = strings.TrimSpace(req.ProductName)
		req.Features = strings.TrimSpace(req.Features)
		if len(req.ProductName) == 0 || len(req.Features) == 0 {
			http.Error(w, "product_name and features are required", http.StatusBadRequest)
			return
		}
		if len(req.ProductName) > 200 || len(req.Features) > 1000 {
			http.Error(w, "Input too long", http.StatusBadRequest)
			return
		}

		desc, err := ai.GenerateDescription(r.Context(), req.ProductName, req.Features)
		if err != nil {
			log.Printf("AI generation error: %v", err)
			http.Error(w, "Failed to generate description", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(generateResponse{Description: desc})
	}
}