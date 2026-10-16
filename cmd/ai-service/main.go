package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"log/slog"
	"net/http"
	"os"
	"time"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/ai"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/aiservice"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/config"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/metrics"
)

func main() {
	healthcheck := flag.Bool("healthcheck", false, "check /healthz and exit")
	flag.Parse()

	cfg := config.Load()

	// Healthcheck mode: used by Docker/K8s health probes.
	if *healthcheck {
		port := cfg.AIServicePort()
		url := fmt.Sprintf("http://localhost:%s/healthz", port)
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()

		req, _ := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
		resp, err := http.DefaultClient.Do(req)
		if err != nil {
			fmt.Fprintf(os.Stderr, "healthcheck failed: %v\n", err)
			os.Exit(1)
		}
		defer func() { _ = resp.Body.Close() }()
		if resp.StatusCode != http.StatusOK {
			fmt.Fprintf(os.Stderr, "healthcheck returned %d\n", resp.StatusCode)
			os.Exit(1)
		}
		os.Exit(0)
	}

	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))

	m := metrics.New("ai-service")

	aiGen := ai.NewFromConfig(cfg, logger, m)
	if aiGen == nil {
		log.Fatal("no AI provider configured: set at least one of GROQ_API_KEY, GEMINI_API_KEY, OPENROUTER_API_KEY or DEEPSEEK_API_KEY")
	}
	logger.Info("AI fallback chain ready", "providers", aiGen.ProviderNames())

	aiservice.Run(cfg, aiGen, logger, m)
}
