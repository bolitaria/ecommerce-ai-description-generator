package ai

import (
	"log/slog"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/config"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/deepseek"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/domain"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/metrics"
)

// NewFromConfig builds a FallbackGenerator from the AI providers configured in
// cfg. Returns nil if no provider is configured (caller must handle this case).
//
// If m is non-nil, each provider client is wrapped with an observed wrapper
// that records per-provider Prometheus metrics.
func NewFromConfig(cfg *config.Config, logger *slog.Logger, m *metrics.Metrics) *FallbackGenerator {
	var providers []namedProvider
	for _, pc := range cfg.AIProviders {
		if pc.APIKey == "" || pc.BaseURL == "" || pc.Model == "" {
			if logger != nil {
				logger.Warn("skipping AI provider with incomplete config", "provider", pc.Name)
			}
			continue
		}
		client := deepseek.NewClient(pc.APIKey, pc.BaseURL, pc.Model)
		var wrapped domain.AIGenerator = client
		if m != nil {
			wrapped = newObservedProvider(pc.Name, client, m)
		}
		providers = append(providers, namedProvider{name: pc.Name, client: wrapped})
	}
	if len(providers) == 0 {
		return nil
	}
	return NewFallbackGenerator(providers, logger, m)
}
