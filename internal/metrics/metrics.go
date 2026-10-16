// Package metrics centralizes Prometheus instrumentation for the ecommerce-ai
// platform. Every service builds its own *Metrics instance with its own
// service label, so the shared dashboards can aggregate or split by service.
package metrics

import (
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/collectors"
)

// Metrics bundles all custom collectors for one service instance.
type Metrics struct {
	registry *prometheus.Registry

	HTTPRequestsTotal    *prometheus.CounterVec
	HTTPRequestDuration  *prometheus.HistogramVec
	HTTPRequestsInFlight prometheus.Gauge

	AIProviderRequestsTotal   *prometheus.CounterVec
	AIProviderRequestDuration *prometheus.HistogramVec
	AIProviderFallbacksTotal  *prometheus.CounterVec
}

// New builds a Metrics instance with its own isolated registry.
// The service label is attached to every metric.
func New(service string) *Metrics {
	reg := prometheus.NewRegistry()

	// Standard Go runtime + process collectors (goroutines, GC, RSS).
	reg.MustRegister(collectors.NewGoCollector())
	reg.MustRegister(collectors.NewProcessCollector(collectors.ProcessCollectorOpts{}))

	labels := prometheus.Labels{"app": service}

	httpRequestsTotal := prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name:        "http_requests_total",
			Help:        "Total number of HTTP requests handled, partitioned by method, path and status.",
			ConstLabels: labels,
		},
		[]string{"method", "path", "status"},
	)

	httpRequestDuration := prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:        "http_request_duration_seconds",
			Help:        "HTTP request latency in seconds.",
			ConstLabels: labels,
			Buckets:     []float64{0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10},
		},
		[]string{"method", "path"},
	)

	httpRequestsInFlight := prometheus.NewGauge(
		prometheus.GaugeOpts{
			Name:        "http_requests_in_flight",
			Help:        "Number of HTTP requests currently being handled.",
			ConstLabels: labels,
		},
	)

	aiProviderRequestsTotal := prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name:        "ai_provider_requests_total",
			Help:        "Total AI provider requests, partitioned by provider, operation and outcome.",
			ConstLabels: labels,
		},
		[]string{"provider", "op", "status"},
	)

	aiProviderRequestDuration := prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:        "ai_provider_request_duration_seconds",
			Help:        "AI provider request latency in seconds.",
			ConstLabels: labels,
			Buckets:     []float64{0.1, 0.25, 0.5, 1, 2.5, 5, 10, 20, 30, 60},
		},
		[]string{"provider", "op"},
	)

	aiProviderFallbacksTotal := prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name:        "ai_provider_fallbacks_total",
			Help:        "Number of times a provider failed and the fallback chain moved to the next one.",
			ConstLabels: labels,
		},
		[]string{"from", "to", "op"},
	)

	reg.MustRegister(
		httpRequestsTotal,
		httpRequestDuration,
		httpRequestsInFlight,
		aiProviderRequestsTotal,
		aiProviderRequestDuration,
		aiProviderFallbacksTotal,
	)

	return &Metrics{
		registry:                  reg,
		HTTPRequestsTotal:         httpRequestsTotal,
		HTTPRequestDuration:       httpRequestDuration,
		HTTPRequestsInFlight:      httpRequestsInFlight,
		AIProviderRequestsTotal:   aiProviderRequestsTotal,
		AIProviderRequestDuration: aiProviderRequestDuration,
		AIProviderFallbacksTotal:  aiProviderFallbacksTotal,
	}
}

// Registry exposes the internal registry so the caller can serve it via
// promhttp.HandlerFor(m.Registry(), ...).
func (m *Metrics) Registry() *prometheus.Registry {
	return m.registry
}
