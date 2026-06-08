package handler

import (
	"encoding/json"
	"log"
	"net/http"
	"strings"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/openai"
)

type translateRequest struct {
	Text       string `json:"text"`
	TargetLang string `json:"target_lang"`
}
type translateResponse struct {
	Translated string `json:"translated"`
}

func TranslateText(ai openai.AIClient) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}
		var req translateRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}
		req.Text = strings.TrimSpace(req.Text)
		req.TargetLang = strings.TrimSpace(req.TargetLang)
		if req.Text == "" || req.TargetLang == "" {
			http.Error(w, "text and target_lang required", http.StatusBadRequest)
			return
		}
		translated, err := ai.TranslateText(r.Context(), req.Text, req.TargetLang)
		if err != nil {
			log.Printf("Translation error: %v", err)
			http.Error(w, "Translation failed", http.StatusInternalServerError)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(translateResponse{Translated: translated})
	}
}
