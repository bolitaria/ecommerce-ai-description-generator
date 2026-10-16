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

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/client"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/config"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/db"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/handler"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/metrics"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/middleware"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/repository"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/service"
)

func Run(cfg *config.Config) {
	if err := db.InitDB(cfg.DatabaseURL); err != nil {
		log.Fatalf("DB init: %v", err)
	}

	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))

	m := metrics.New("core-api")

	// Build the HTTP client to the AI microservice.
	aiGen := client.New(cfg.AIServiceURL, cfg.InternalAPIToken, logger)
	logger.Info("ai-service client configured", "url", cfg.AIServiceURL)

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

	businessMux := http.NewServeMux()

	businessMux.HandleFunc("/health", handler.HealthCheck())
	businessMux.HandleFunc("/api/v1/departments", deptH.List)

	businessMux.HandleFunc("/api/v1/products", func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			productH.List(w, r)
		case http.MethodPost:
			productH.Create(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	})

	businessMux.HandleFunc("/api/v1/products/", func(w http.ResponseWriter, r *http.Request) {
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

	businessMux.Handle("/api/v1/generate", genH)
	businessMux.Handle("/api/v1/translate", transH)
	businessMux.Handle("/api/v1/email", emailH)
	businessMux.HandleFunc("/api/v1/products/import", importH.ServeHTTP)
	businessMux.HandleFunc("/api/v1/products/import/preview", importH.ServeHTTP)
	businessMux.HandleFunc("/api/v1/products/import/template", importH.ServeHTTP)

	allowedOrigins := []string{"http://localhost:5173"}
	businessHandler := middleware.CORS(allowedOrigins)(
		middleware.Recovery(
			middleware.Logging(
				middleware.RateLimitPerIP(cfg.RateLimit)(
					m.HTTPMiddleware(businessMux),
				),
			),
		),
	)

	// Root mux: business routes (wrapped) + raw /metrics (unwrapped).
	root := http.NewServeMux()
	root.Handle("/", businessHandler)
	root.Handle("/metrics", m.Handler())

	srv := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      root,
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
