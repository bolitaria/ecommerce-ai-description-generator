package server

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/config"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/db"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/handler"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/middleware"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/openai"
)

func Run(cfg *config.Config) {
	if err := db.InitDB(cfg.DBPath); err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}

	aiClient := openai.NewClient(cfg.OpenAIKey, cfg.OpenAIURL, cfg.OpenAIModel)

	mux := http.NewServeMux()
	mux.HandleFunc("/health", handler.HealthCheck())
	mux.HandleFunc("/api/departments", handler.GetDepartments())
	mux.HandleFunc("/api/products", handler.ProductsHandler())
	mux.HandleFunc("/api/products/", handler.ProductByIDHandler())
	mux.HandleFunc("/generate", handler.GenerateDescription(aiClient))
	mux.HandleFunc("/translate", handler.TranslateText(aiClient))
	mux.HandleFunc("/email", handler.GenerateEmail(aiClient))

	wrapped := middleware.CORS(middleware.Recovery(middleware.Logging(middleware.RateLimitPerIP(cfg.RateLimit)(mux))))

	srv := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      wrapped,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		log.Printf("Server starting on port %s", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("listen: %s\n", err)
		}
	}()

	<-quit
	log.Println("Shutting down server...")
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}
	log.Println("Server exited gracefully")
}
