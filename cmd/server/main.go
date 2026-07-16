package main

import (
	"log"
	"os"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/config"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/server"
)

func main() {
	if os.Getenv("DeepSeek_API_KEY") == "" && os.Getenv("ENV") != "mock" {
		log.Fatal("DeepSeek_API_KEY environment variable is required")
	}
	cfg := config.Load()
	server.Run(cfg)
}