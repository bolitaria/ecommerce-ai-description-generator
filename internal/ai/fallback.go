package ai

import (
	"context"
	"fmt"
	"log/slog"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/domain"
)

// namedProvider pairs a provider name with its client.
type namedProvider struct {
	name   string
	client domain.AIGenerator
}

// FallbackGenerator implements domain.AIGenerator by trying each provider
// in priority order until one succeeds.
type FallbackGenerator struct {
	providers []namedProvider
	logger    *slog.Logger
}

// NewFallbackGenerator builds a generator from an ordered list of providers.
// If logger is nil, slog.Default() is used.
func NewFallbackGenerator(providers []namedProvider, logger *slog.Logger) *FallbackGenerator {
	if logger == nil {
		logger = slog.Default()
	}
	return &FallbackGenerator{providers: providers, logger: logger}
}

func (f *FallbackGenerator) GenerateDescription(ctx context.Context, productName, features string) (string, error) {
	var lastErr error
	for _, p := range f.providers {
		f.logger.Info("trying AI provider", "provider", p.name, "op", "generate_description")
		res, err := p.client.GenerateDescription(ctx, productName, features)
		if err == nil {
			return res, nil
		}
		lastErr = err
		f.logger.Warn("AI provider failed", "provider", p.name, "op", "generate_description", "error", err)
	}
	return "", fmt.Errorf("all AI providers failed: %w", lastErr)
}

func (f *FallbackGenerator) TranslateText(ctx context.Context, text, targetLang string) (string, error) {
	var lastErr error
	for _, p := range f.providers {
		f.logger.Info("trying AI provider", "provider", p.name, "op", "translate")
		res, err := p.client.TranslateText(ctx, text, targetLang)
		if err == nil {
			return res, nil
		}
		lastErr = err
		f.logger.Warn("AI provider failed", "provider", p.name, "op", "translate", "error", err)
	}
	return "", fmt.Errorf("all AI providers failed: %w", lastErr)
}

func (f *FallbackGenerator) GenerateEmail(ctx context.Context, productName, features string) (subject, body string, err error) {
	var lastErr error
	for _, p := range f.providers {
		f.logger.Info("trying AI provider", "provider", p.name, "op", "generate_email")
		s, b, err := p.client.GenerateEmail(ctx, productName, features)
		if err == nil {
			return s, b, nil
		}
		lastErr = err
		f.logger.Warn("AI provider failed", "provider", p.name, "op", "generate_email", "error", err)
	}
	return "", "", fmt.Errorf("all AI providers failed: %w", lastErr)
}

// ProviderNames returns the names of the providers in priority order.
func (f *FallbackGenerator) ProviderNames() []string {
	names := make([]string, len(f.providers))
	for i, p := range f.providers {
		names[i] = p.name
	}
	return names
}

// Compile-time assertion: FallbackGenerator satisfies domain.AIGenerator.
var _ domain.AIGenerator = (*FallbackGenerator)(nil)
