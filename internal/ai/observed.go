package ai

import (
	"context"
	"time"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/domain"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/metrics"
)

// observedProvider wraps a domain.AIGenerator and records per-provider
// Prometheus metrics: request count (by outcome) and latency.
//
// It sits between FallbackGenerator and the raw provider client, so every
// attempt (including the ones that fail and trigger a fallback) is recorded.
type observedProvider struct {
	name    string
	inner   domain.AIGenerator
	metrics *metrics.Metrics
}

func newObservedProvider(name string, inner domain.AIGenerator, m *metrics.Metrics) *observedProvider {
	return &observedProvider{name: name, inner: inner, metrics: m}
}

func (p *observedProvider) record(op string, start time.Time, err error) {
	status := "success"
	if err != nil {
		status = "error"
	}
	p.metrics.AIProviderRequestsTotal.WithLabelValues(p.name, op, status).Inc()
	p.metrics.AIProviderRequestDuration.WithLabelValues(p.name, op).Observe(time.Since(start).Seconds())
}

func (p *observedProvider) GenerateDescription(ctx context.Context, productName, features string) (string, error) {
	start := time.Now()
	res, err := p.inner.GenerateDescription(ctx, productName, features)
	p.record("generate_description", start, err)
	return res, err
}

func (p *observedProvider) TranslateText(ctx context.Context, text, targetLang string) (string, error) {
	start := time.Now()
	res, err := p.inner.TranslateText(ctx, text, targetLang)
	p.record("translate", start, err)
	return res, err
}

func (p *observedProvider) GenerateEmail(ctx context.Context, productName, features string) (string, string, error) {
	start := time.Now()
	sub, body, err := p.inner.GenerateEmail(ctx, productName, features)
	p.record("generate_email", start, err)
	return sub, body, err
}

var _ domain.AIGenerator = (*observedProvider)(nil)
