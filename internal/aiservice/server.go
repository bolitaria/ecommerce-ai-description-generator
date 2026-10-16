package aiservice

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/config"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/domain"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/metrics"
)

// Run starts the AI Service HTTP server and blocks until SIGINT/SIGTERM.
// If m is non-nil, HTTP requests are instrumented and /metrics is exposed.
func Run(cfg *config.Config, ai domain.AIGenerator, logger *slog.Logger, m *metrics.Metrics) {
	router := NewRouter(ai, cfg.InternalAPIToken, logger, m)

	srv := &http.Server{
		Addr:              ":" + cfg.AIServicePort(),
		Handler:           router,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      60 * time.Second, // AI calls can be slow
		IdleTimeout:       120 * time.Second,
	}

	// Run server in background.
	errCh := make(chan error, 1)
	go func() {
		logger.Info("ai-service listening", "port", cfg.AIServicePort())
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			errCh <- err
		}
	}()

	// Wait for shutdown signal or server error.
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	select {
	case err := <-errCh:
		logger.Error("server error", "error", err)
		os.Exit(1)
	case sig := <-quit:
		logger.Info("shutdown signal received", "signal", sig.String())
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		logger.Error("graceful shutdown failed", "error", err)
		os.Exit(1)
	}
	logger.Info("ai-service stopped gracefully")
}
