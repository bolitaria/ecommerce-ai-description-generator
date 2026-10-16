package aiservice

import (
	"log/slog"
	"net/http"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/domain"
)

// NewRouter builds the HTTP router for the AI Service.
func NewRouter(ai domain.AIGenerator, internalToken string, logger *slog.Logger) http.Handler {
	mux := http.NewServeMux()

	// API endpoints.
	mux.Handle("/v1/descriptions", NewDescriptionHandler(ai, logger))
	mux.Handle("/v1/translations", NewTranslateHandler(ai, logger))
	mux.Handle("/v1/emails", NewEmailHandler(ai, logger))

	// Operational endpoints (bypass auth).
	mux.HandleFunc("/healthz", HealthHandler())
	mux.HandleFunc("/readyz", ReadyHandler())

	// Middleware chain (outermost first).
	// Order matters: Recovery -> TraceID -> Auth -> Logger -> mux
	return Recovery(logger)(
		TraceID(
			InternalAuth(internalToken, logger)(
				RequestLogger(logger)(mux),
			),
		),
	)
}
