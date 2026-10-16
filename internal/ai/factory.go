package ai

import (
	"log/slog"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/config"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/deepseek"
)

// NewFromConfig builds a FallbackGenerator from the AI providers configured in
// cfg. Returns nil if no provider is configured (caller must handle this case).
func NewFromConfig(cfg *config.Config, logger *slog.Logger) *FallbackGenerator {
	var providers []namedProvider
	for _, pc := range cfg.AIProviders {
		if pc.APIKey == "" || pc.BaseURL == "" || pc.Model == "" {
			if logger != nil {
				logger.Warn("skipping AI provider with incomplete config", "provider", pc.Name)
			}
			continue
		}
		client := deepseek.NewClient(pc.APIKey, pc.BaseURL, pc.Model)
		providers = append(providers, namedProvider{name: pc.Name, client: client})
	}
	if len(providers) == 0 {
		return nil
	}
	return NewFallbackGenerator(providers, logger)
}
