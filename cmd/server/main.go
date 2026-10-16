package main

import (
	"log"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/config"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/server"
)

func main() {
	cfg := config.Load()
	if len(cfg.AIProviders) == 0 && cfg.Environment != "mock" {
		log.Fatal("no AI provider configured: set at least one of GROQ_API_KEY, GEMINI_API_KEY, OPENROUTER_API_KEY or DEEPSEEK_API_KEY")
	}
	server.Run(cfg)
}
