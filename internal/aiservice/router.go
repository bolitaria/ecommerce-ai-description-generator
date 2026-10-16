package aiservice

import (
	"log/slog"
	"net/http"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/domain"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/metrics"
)

// NewRouter builds the HTTP router for the AI Service.
// If m is non-nil, business endpoints are instrumented with RED metrics
// and a /metrics endpoint is exposed (unauthenticated, unwrapped).
func NewRouter(ai domain.AIGenerator, internalToken string, logger *slog.Logger, m *metrics.Metrics) http.Handler {
	businessMux := http.NewServeMux()

	// API endpoints.
	businessMux.Handle("/v1/descriptions", NewDescriptionHandler(ai, logger))
	businessMux.Handle("/v1/translations", NewTranslateHandler(ai, logger))
	businessMux.Handle("/v1/emails", NewEmailHandler(ai, logger))

	// Operational endpoints (bypass auth).
	businessMux.HandleFunc("/healthz", HealthHandler())
	businessMux.HandleFunc("/readyz", ReadyHandler())

	// Business middleware chain (innermost: metrics, outermost: recovery).
	inner := http.Handler(businessMux)
	if m != nil {
		inner = m.HTTPMiddleware(inner)
	}
	businessHandler := Recovery(logger)(
		TraceID(
			InternalAuth(internalToken, logger)(
				RequestLogger(logger)(inner),
			),
		),
	)

	// Root mux: business routes + raw /metrics (not rate-limited, not auth'd).
	root := http.NewServeMux()
	root.Handle("/", businessHandler)
	if m != nil {
		root.Handle("/metrics", m.Handler())
	}
	return root
}
