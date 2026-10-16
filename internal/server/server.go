package server

import (
	"context"
	"log"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/ai"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/config"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/db"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/handler"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/middleware"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/repository"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/service"
)

func Run(cfg *config.Config) {
	if err := db.InitDB(cfg.DatabaseURL); err != nil {
		log.Fatalf("DB init: %v", err)
	}

	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))

	// Build the AI provider fallback chain from config.
	// Returns nil if no provider has an API key configured.
	aiGen := ai.NewFromConfig(cfg, logger)
	if aiGen == nil {
		log.Fatal("no AI provider configured: set at least one of GROQ_API_KEY, GEMINI_API_KEY, OPENROUTER_API_KEY or DEEPSEEK_API_KEY")
	}
	logger.Info("AI fallback chain ready", "providers", aiGen.ProviderNames())

	productRepo := repository.NewProductRepo(db.DB)
	departmentRepo := repository.NewDepartmentRepo(db.DB)

	productSvc := service.NewProductService(productRepo, aiGen)
	aiSvc := service.NewAIService(aiGen)

	productH := handler.NewProductHandler(productSvc)
	deptH := handler.NewDepartmentHandler(departmentRepo)
	genH := handler.NewGenerateHandler(aiSvc)
	transH := handler.NewTranslateHandler(aiSvc)
	emailH := handler.NewEmailHandler(aiSvc)
	importH := handler.NewImportHandler(productSvc)

	mux := http.NewServeMux()

	mux.HandleFunc("/health", handler.HealthCheck())
	mux.HandleFunc("/api/v1/departments", deptH.List)

	mux.HandleFunc("/api/v1/products", func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			productH.List(w, r)
		case http.MethodPost:
			productH.Create(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	})

	mux.HandleFunc("/api/v1/products/", func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			productH.GetByID(w, r)
		case http.MethodPut:
			productH.Update(w, r)
		case http.MethodDelete:
			productH.Delete(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	})

	mux.Handle("/api/v1/generate", genH)
	mux.Handle("/api/v1/translate", transH)
	mux.Handle("/api/v1/email", emailH)
	mux.HandleFunc("/api/v1/products/import", importH.ServeHTTP)
	mux.HandleFunc("/api/v1/products/import/preview", importH.ServeHTTP)
	mux.HandleFunc("/api/v1/products/import/template", importH.ServeHTTP)

	allowedOrigins := []string{"http://localhost:5173"}
	wrapped := middleware.CORS(allowedOrigins)(
		middleware.Recovery(
			middleware.Logging(
				middleware.RateLimitPerIP(cfg.RateLimit)(mux),
			),
		),
	)

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
	log.Println("Shutting down...")
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Shutdown: %v", err)
	}
	log.Println("Server exited gracefully")
}
