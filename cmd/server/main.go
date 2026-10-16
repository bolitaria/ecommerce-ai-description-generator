package main

import (
	"log"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/config"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/server"
)

func main() {
	cfg := config.Load()
	if cfg.AIServiceURL == "" {
		log.Fatal("AI_SERVICE_URL is required")
	}
	if cfg.InternalAPIToken == "" && cfg.Environment != "mock" {
		log.Fatal("INTERNAL_API_TOKEN is required (set ENV=mock to skip in local dev)")
	}
	server.Run(cfg)
}
