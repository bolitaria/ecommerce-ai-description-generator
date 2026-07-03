#!/usr/bin/env bash
set -euo pipefail

# ─── Configuración ───────────────────────────────────────────────
PROJECT_DIR="$(pwd)"
BACKUP_DIR="${PROJECT_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
echo "📦 Creando backup en $BACKUP_DIR ..."
cp -r "$PROJECT_DIR" "$BACKUP_DIR"

echo "🚀 Aplicando mejoras profesionales al proyecto..."
echo ""

# ─── 1. Nuevos archivos de dominio, repositorio y servicio ──────

mkdir -p internal/domain internal/repository internal/service internal/auth internal/telemetry internal/validator

cat > internal/domain/product.go <<'EOF'
package domain

type Product struct {
	ID           int    `json:"id"`
	Name         string `json:"name"`
	Features     string `json:"features"`
	Description  string `json:"description"`
	DepartmentID int    `json:"department_id"`
}

type ProductRepository interface {
	List(filter ProductFilter, page, limit int) ([]Product, int, error)
	GetByID(id int) (*Product, error)
	Create(p Product) (int, error)
	Update(p Product) error
	Delete(id int) error
}

type ProductFilter struct {
	DepartmentID *int
	Search       string
}
EOF

cat > internal/domain/department.go <<'EOF'
package domain

type Department struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
}

type DepartmentRepository interface {
	ListAll() ([]Department, error)
}
EOF

cat > internal/domain/ai.go <<'EOF'
package domain

import "context"

type AIGenerator interface {
	GenerateDescription(ctx context.Context, productName, features string) (string, error)
	TranslateText(ctx context.Context, text, targetLang string) (string, error)
	GenerateEmail(ctx context.Context, productName, features string) (subject, body string, err error)
}
EOF

# Repository implementations will use PostgreSQL (we'll replace db/db.go later)
cat > internal/repository/product_repo.go <<'EOF'
package repository

import (
	"database/sql"
	"fmt"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/domain"
)

type productRepo struct {
	db *sql.DB
}

func NewProductRepo(db *sql.DB) domain.ProductRepository {
	return &productRepo{db: db}
}

func (r *productRepo) List(filter domain.ProductFilter, page, limit int) ([]domain.Product, int, error) {
	base := `FROM products p JOIN departments d ON p.department_id = d.id WHERE 1=1`
	args := []interface{}{}
	if filter.DepartmentID != nil {
		base += " AND p.department_id = $1"
		args = append(args, *filter.DepartmentID)
	}
	if filter.Search != "" {
		idx := len(args) + 1
		base += fmt.Sprintf(" AND p.name ILIKE $%d", idx)
		args = append(args, "%"+filter.Search+"%")
	}

	var total int
	countQuery := "SELECT COUNT(*) " + base
	if err := r.db.QueryRow(countQuery, args...).Scan(&total); err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * limit
	query := "SELECT p.id, p.name, p.features, p.description, p.department_id " + base + " ORDER BY p.id DESC LIMIT $" + fmt.Sprintf("%d", len(args)+1) + " OFFSET $" + fmt.Sprintf("%d", len(args)+2)
	args = append(args, limit, offset)

	rows, err := r.db.Query(query, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var products []domain.Product
	for rows.Next() {
		var p domain.Product
		if err := rows.Scan(&p.ID, &p.Name, &p.Features, &p.Description, &p.DepartmentID); err != nil {
			return nil, 0, err
		}
		products = append(products, p)
	}
	return products, total, nil
}

func (r *productRepo) GetByID(id int) (*domain.Product, error) {
	p := &domain.Product{}
	err := r.db.QueryRow("SELECT id, name, features, description, department_id FROM products WHERE id=$1", id).
		Scan(&p.ID, &p.Name, &p.Features, &p.Description, &p.DepartmentID)
	if err != nil {
		return nil, err
	}
	return p, nil
}

func (r *productRepo) Create(p domain.Product) (int, error) {
	var id int
	err := r.db.QueryRow("INSERT INTO products (name, features, department_id) VALUES ($1, $2, $3) RETURNING id",
		p.Name, p.Features, p.DepartmentID).Scan(&id)
	return id, err
}

func (r *productRepo) Update(p domain.Product) error {
	_, err := r.db.Exec("UPDATE products SET name=$1, features=$2, description=$3, department_id=$4 WHERE id=$5",
		p.Name, p.Features, p.Description, p.DepartmentID, p.ID)
	return err
}

func (r *productRepo) Delete(id int) error {
	_, err := r.db.Exec("DELETE FROM products WHERE id=$1", id)
	return err
}
EOF

cat > internal/repository/department_repo.go <<'EOF'
package repository

import (
	"database/sql"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/domain"
)

type departmentRepo struct {
	db *sql.DB
}

func NewDepartmentRepo(db *sql.DB) domain.DepartmentRepository {
	return &departmentRepo{db: db}
}

func (r *departmentRepo) ListAll() ([]domain.Department, error) {
	rows, err := r.db.Query("SELECT id, name FROM departments ORDER BY name")
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var deps []domain.Department
	for rows.Next() {
		var d domain.Department
		if err := rows.Scan(&d.ID, &d.Name); err != nil {
			return nil, err
		}
		deps = append(deps, d)
	}
	return deps, nil
}
EOF

# Service layer (business logic)
cat > internal/service/product_service.go <<'EOF'
package service

import (
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/domain"
)

type ProductService struct {
	repo domain.ProductRepository
}

func NewProductService(repo domain.ProductRepository) *ProductService {
	return &ProductService{repo: repo}
}

func (s *ProductService) List(filter domain.ProductFilter, page, limit int) ([]domain.Product, int, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}
	return s.repo.List(filter, page, limit)
}

func (s *ProductService) Create(p domain.Product) (int, error) {
	// Basic validation
	if p.Name == "" || p.Features == "" {
		return 0, domain.ErrValidation("name and features required")
	}
	return s.repo.Create(p)
}

func (s *ProductService) Update(p domain.Product) error {
	return s.repo.Update(p)
}

func (s *ProductService) Delete(id int) error {
	return s.repo.Delete(id)
}
EOF

# Add error types in domain
cat > internal/domain/errors.go <<'EOF'
package domain

type ValidationError struct {
	message string
}

func (e *ValidationError) Error() string {
	return e.message
}

func ErrValidation(msg string) error {
	return &ValidationError{message: msg}
}
EOF

# AI Service with caching / circuit breaker (basic for now)
cat > internal/service/ai_service.go <<'EOF'
package service

import (
	"context"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/domain"
)

type AIService struct {
	ai domain.AIGenerator
}

func NewAIService(ai domain.AIGenerator) *AIService {
	return &AIService{ai: ai}
}

func (s *AIService) GenerateDescription(ctx context.Context, productName, features string) (string, error) {
	return s.ai.GenerateDescription(ctx, productName, features)
}

func (s *AIService) TranslateText(ctx context.Context, text, targetLang string) (string, error) {
	return s.ai.TranslateText(ctx, text, targetLang)
}

func (s *AIService) GenerateEmail(ctx context.Context, productName, features string) (string, string, error) {
	return s.ai.GenerateEmail(ctx, productName, features)
}
EOF

# ─── 2. Configuración mejorada ─────────────────────────────────
cat > internal/config/config.go <<'EOF'
package config

import "os"

type Config struct {
	Port        string
	OpenAIKey   string
	OpenAIURL   string
	OpenAIModel string
	MaxTokens   int
	RateLimit   float64
	Environment string
	DBPath      string
	// Nuevas
	DatabaseURL string
	JWTSecret   string
	RedisURL    string
}

func Load() *Config {
	return &Config{
		Port:        getEnv("PORT", "8080"),
		OpenAIKey:   os.Getenv("OPENAI_API_KEY"),
		OpenAIURL:   getEnv("OPENAI_URL", "https://api.openai.com/v1"),
		OpenAIModel: getEnv("OPENAI_MODEL", "gpt-3.5-turbo"),
		MaxTokens:   300,
		RateLimit:   5.0,
		Environment: getEnv("ENV", "development"),
		DBPath:      getEnv("DB_PATH", "./data/store.db"),
		DatabaseURL: getEnv("DATABASE_URL", "postgres://user:pass@localhost:5432/store?sslmode=disable"),
		JWTSecret:   getEnv("JWT_SECRET", "dev-secret-change-me"),
		RedisURL:    getEnv("REDIS_URL", "redis://localhost:6379"),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
EOF

# ─── 3. Migración de base de datos a PostgreSQL ─────────────────
mkdir -p db/migrations
cat > db/migrations/000001_init.up.sql <<'EOF'
CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    features TEXT NOT NULL,
    description TEXT DEFAULT '',
    department_id INTEGER NOT NULL REFERENCES departments(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
INSERT INTO departments (name) VALUES
    ('Stickers'),
    ('Apparel'),
    ('Drinkware'),
    ('Home & Living'),
    ('Accessories')
ON CONFLICT DO NOTHING;
INSERT INTO products (name, features, description, department_id) VALUES
    ('Sticker Pack', 'Waterproof, UV-resistant, 5x5cm', 'High-quality waterproof stickers perfect for outdoor use.', 1),
    ('Custom T-Shirt', '100% cotton, screen-printed, unisex', 'Comfortable and stylish custom t-shirts.', 2),
    ('Mug 11oz', 'Ceramic, dishwasher safe, vibrant print', 'Start your day with a smile using our custom mugs.', 3),
    ('Tote Bag', 'Eco-friendly canvas, reinforced stitching', 'Eco-friendly tote bags for everyday use.', 4),
    ('Phone Case', 'Shock-absorbent TPU, wireless charging compatible', 'Protect your phone in style.', 5),
    ('Hoodie', 'Fleece lining, adjustable hood, kangaroo pocket', 'Stay warm with customizable hoodies.', 2)
ON CONFLICT DO NOTHING;
EOF

cat > db/migrations/000001_init.down.sql <<'EOF'
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS departments;
EOF

# Replace the old db package with a PostgreSQL-aware version
rm internal/db/sqlite.go 2>/dev/null || true
cat > internal/db/db.go <<'EOF'
package db

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"path/filepath"

	_ "github.com/lib/pq"
)

var DB *sql.DB

// InitDB opens a PostgreSQL connection and runs migrations.
func InitDB(databaseURL string) error {
	var err error
	DB, err = sql.Open("postgres", databaseURL)
	if err != nil {
		return fmt.Errorf("open db: %w", err)
	}
	if err = DB.Ping(); err != nil {
		return fmt.Errorf("ping db: %w", err)
	}
	if err = runMigrations(); err != nil {
		return fmt.Errorf("migrate: %w", err)
	}
	log.Println("Database initialized (PostgreSQL)")
	return nil
}

func runMigrations() error {
	// Simple migration runner: looks for .sql files in db/migrations
	migrationPath := filepath.Join("db", "migrations")
	files, err := os.ReadDir(migrationPath)
	if err != nil {
		return err
	}
	for _, f := range files {
		if !f.IsDir() && filepath.Ext(f.Name()) == ".sql" {
			content, err := os.ReadFile(filepath.Join(migrationPath, f.Name()))
			if err != nil {
				return err
			}
			if _, err := DB.Exec(string(content)); err != nil {
				return fmt.Errorf("executing %s: %w", f.Name(), err)
			}
			log.Printf("Applied migration: %s", f.Name())
		}
	}
	return nil
}
EOF

# Remove old seed file logic, now in migration
rm internal/db/seed.go 2>/dev/null || true

# ─── 4. Handlers mejorados ──────────────────────────────────────
cat > internal/handler/department.go <<'EOF'
package handler

import (
	"encoding/json"
	"net/http"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/domain"
)

type DepartmentHandler struct {
	repo domain.DepartmentRepository
}

func NewDepartmentHandler(repo domain.DepartmentRepository) *DepartmentHandler {
	return &DepartmentHandler{repo: repo}
}

func (h *DepartmentHandler) List(w http.ResponseWriter, r *http.Request) {
	deps, err := h.repo.ListAll()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"departments": deps})
}
EOF

cat > internal/handler/product.go <<'EOF'
package handler

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/domain"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/service"
)

type ProductHandler struct {
	svc *service.ProductService
}

func NewProductHandler(svc *service.ProductService) *ProductHandler {
	return &ProductHandler{svc: svc}
}

func (h *ProductHandler) List(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	filter := domain.ProductFilter{}
	if depID := q.Get("department_id"); depID != "" {
		id, err := strconv.Atoi(depID)
		if err == nil {
			filter.DepartmentID = &id
		}
	}
	filter.Search = q.Get("search")
	page, _ := strconv.Atoi(q.Get("page"))
	limit, _ := strconv.Atoi(q.Get("limit"))

	products, total, err := h.svc.List(filter, page, limit)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"data":  products,
		"total": total,
		"page":  page,
		"limit": limit,
	}
	writeJSON(w, http.StatusOK, response)
}

func (h *ProductHandler) Create(w http.ResponseWriter, r *http.Request) {
	var p domain.Product
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON")
		return
	}
	id, err := h.svc.Create(p)
	if err != nil {
		if _, ok := err.(*domain.ValidationError); ok {
			writeError(w, http.StatusBadRequest, err.Error())
			return
		}
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	writeJSON(w, http.StatusCreated, map[string]interface{}{"id": id})
}

func (h *ProductHandler) Update(w http.ResponseWriter, r *http.Request) {
	id, err := parseID(r.URL.Path, "/api/v1/products/")
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid id")
		return
	}
	var p domain.Product
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON")
		return
	}
	p.ID = id
	if err := h.svc.Update(p); err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	w.WriteHeader(http.StatusOK)
}

func (h *ProductHandler) Delete(w http.ResponseWriter, r *http.Request) {
	id, err := parseID(r.URL.Path, "/api/v1/products/")
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid id")
		return
	}
	if err := h.svc.Delete(id); err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	w.WriteHeader(http.StatusOK)
}

// Helpers
func parseID(path, prefix string) (int, error) {
	idStr := strings.TrimPrefix(path, prefix)
	return strconv.Atoi(idStr)
}

func writeJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func writeError(w http.ResponseWriter, status int, msg string) {
	writeJSON(w, status, map[string]string{"error": msg})
}
EOF

# AI handlers now use service
cat > internal/handler/generate.go <<'EOF'
package handler

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/service"
)

type GenerateHandler struct {
	aiSvc *service.AIService
}

func NewGenerateHandler(aiSvc *service.AIService) *GenerateHandler {
	return &GenerateHandler{aiSvc: aiSvc}
}

func (h *GenerateHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}
	var req struct {
		ProductName string `json:"product_name"`
		Features    string `json:"features"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON")
		return
	}
	req.ProductName = strings.TrimSpace(req.ProductName)
	req.Features = strings.TrimSpace(req.Features)
	if req.ProductName == "" || req.Features == "" {
		writeError(w, http.StatusBadRequest, "product_name and features required")
		return
	}
	desc, err := h.aiSvc.GenerateDescription(r.Context(), req.ProductName, req.Features)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "generation failed")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"description": desc})
}
EOF

cat > internal/handler/translate.go <<'EOF'
package handler

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/service"
)

type TranslateHandler struct {
	aiSvc *service.AIService
}

func NewTranslateHandler(aiSvc *service.AIService) *TranslateHandler {
	return &TranslateHandler{aiSvc: aiSvc}
}

func (h *TranslateHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}
	var req struct {
		Text       string `json:"text"`
		TargetLang string `json:"target_lang"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON")
		return
	}
	req.Text = strings.TrimSpace(req.Text)
	req.TargetLang = strings.TrimSpace(req.TargetLang)
	if req.Text == "" || req.TargetLang == "" {
		writeError(w, http.StatusBadRequest, "text and target_lang required")
		return
	}
	trans, err := h.aiSvc.TranslateText(r.Context(), req.Text, req.TargetLang)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "translation failed")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"translated": trans})
}
EOF

cat > internal/handler/email.go <<'EOF'
package handler

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/service"
)

type EmailHandler struct {
	aiSvc *service.AIService
}

func NewEmailHandler(aiSvc *service.AIService) *EmailHandler {
	return &EmailHandler{aiSvc: aiSvc}
}

func (h *EmailHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}
	var req struct {
		ProductName string `json:"product_name"`
		Features    string `json:"features"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON")
		return
	}
	req.ProductName = strings.TrimSpace(req.ProductName)
	req.Features = strings.TrimSpace(req.Features)
	if req.ProductName == "" || req.Features == "" {
		writeError(w, http.StatusBadRequest, "product_name and features required")
		return
	}
	subj, body, err := h.aiSvc.GenerateEmail(r.Context(), req.ProductName, req.Features)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "email generation failed")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"subject": subj, "body": body})
}
EOF

# Health handler remains similar
cat > internal/handler/health.go <<'EOF'
package handler

import "net/http"

func HealthCheck() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"status":"ok"}`))
	}
}
EOF

# ─── 5. Middlewares mejorados ───────────────────────────────────
# CORS restrictivo
cat > internal/middleware/cors.go <<'EOF'
package middleware

import "net/http"

func CORS(allowedOrigins []string) func(http.Handler) http.Handler {
	originMap := make(map[string]bool)
	for _, o := range allowedOrigins {
		originMap[o] = true
	}
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			origin := r.Header.Get("Origin")
			if origin != "" && originMap[origin] {
				w.Header().Set("Access-Control-Allow-Origin", origin)
			}
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			if r.Method == http.MethodOptions {
				w.WriteHeader(http.StatusOK)
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}
EOF

# Rate limit with Redis (placeholder, keeps in-memory)
cat > internal/middleware/ratelimit.go <<'EOF'
package middleware

import (
	"net/http"
	"sync"
	"golang.org/x/time/rate"
)

func RateLimitPerIP(rps float64) func(http.Handler) http.Handler {
	var mu sync.Mutex
	visitors := make(map[string]*rate.Limiter)

	getLimiter := func(ip string) *rate.Limiter {
		mu.Lock()
		defer mu.Unlock()
		limiter, exists := visitors[ip]
		if !exists {
			limiter = rate.NewLimiter(rate.Limit(rps), int(rps*2))
			visitors[ip] = limiter
		}
		return limiter
	}

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ip := r.RemoteAddr
			if !getLimiter(ip).Allow() {
				http.Error(w, "Rate limit exceeded", http.StatusTooManyRequests)
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}
EOF

# Logging with trace id (keeps uuid)
# Recovery with error mapping
cat > internal/middleware/recovery.go <<'EOF'
package middleware

import (
	"log"
	"net/http"
	"runtime/debug"
)

func Recovery(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				log.Printf("PANIC: %v\n%s", err, debug.Stack())
				http.Error(w, `{"error":"internal server error"}`, http.StatusInternalServerError)
			}
		}()
		next.ServeHTTP(w, r)
	})
}
EOF

# ─── 6. Cliente OpenAI con circuit breaker y caché básico ──────
cat > internal/openai/client.go <<'EOF'
package openai

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
	"github.com/sony/gobreaker"
)

type AIClient interface {
	GenerateDescription(ctx context.Context, productName, features string) (string, error)
	TranslateText(ctx context.Context, text, targetLang string) (string, error)
	GenerateEmail(ctx context.Context, productName, features string) (subject, body string, err error)
}

type client struct {
	httpClient *http.Client
	apiKey     string
	baseURL    string
	model      string
	cb         *gobreaker.CircuitBreaker
}

func NewClient(apiKey, baseURL, model string) AIClient {
	settings := gobreaker.Settings{
		Name:        "openai",
		MaxRequests: 3,
		Interval:    10 * time.Second,
		Timeout:     30 * time.Second,
		ReadyToTrip: func(counts gobreaker.Counts) bool {
			return counts.ConsecutiveFailures > 5
		},
	}
	return &client{
		httpClient: &http.Client{Timeout: 20 * time.Second},
		apiKey:     apiKey,
		baseURL:    baseURL,
		model:      model,
		cb:         gobreaker.NewCircuitBreaker(settings),
	}
}

type openAIRequest struct {
	Model     string          `json:"model"`
	Messages  []openAIMessage `json:"messages"`
	MaxTokens int             `json:"max_tokens"`
}
type openAIMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}
type openAIResponse struct {
	Choices []struct {
		Message struct {
			Content string `json:"content"`
		} `json:"message"`
	} `json:"choices"`
}

func (c *client) chatCompletion(ctx context.Context, prompt string, maxTokens int) (string, error) {
	reqBody := openAIRequest{
		Model: c.model,
		Messages: []openAIMessage{
			{Role: "user", Content: prompt},
		},
		MaxTokens: maxTokens,
	}
	bodyBytes, err := json.Marshal(reqBody)
	if err != nil {
		return "", err
	}
	// Circuit breaker
	body, err := c.cb.Execute(func() (interface{}, error) {
		req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+"/chat/completions", bytes.NewReader(bodyBytes))
		if err != nil {
			return "", err
		}
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+c.apiKey)
		resp, err := c.httpClient.Do(req)
		if err != nil {
			return "", err
		}
		defer resp.Body.Close()
		if resp.StatusCode != http.StatusOK {
			b, _ := io.ReadAll(resp.Body)
			return "", fmt.Errorf("openai error %d: %s", resp.StatusCode, string(b))
		}
		var aiResp openAIResponse
		if err := json.NewDecoder(resp.Body).Decode(&aiResp); err != nil {
			return "", err
		}
		if len(aiResp.Choices) == 0 {
			return "", fmt.Errorf("no choices")
		}
		return aiResp.Choices[0].Message.Content, nil
	})
	if err != nil {
		return "", err
	}
	return body.(string), nil
}

func (c *client) GenerateDescription(ctx context.Context, productName, features string) (string, error) {
	prompt := fmt.Sprintf("Write a compelling e-commerce product description for '%s'. Key features: %s. Keep under 150 words.", productName, features)
	return c.chatCompletion(ctx, prompt, 300)
}

func (c *client) TranslateText(ctx context.Context, text, targetLang string) (string, error) {
	prompt := fmt.Sprintf("Translate the following text to %s. Only return the translation:\n\n%s", targetLang, text)
	return c.chatCompletion(ctx, prompt, 300)
}

func (c *client) GenerateEmail(ctx context.Context, productName, features string) (string, string, error) {
	prompt := fmt.Sprintf(`Write a marketing email for "%s" with features: %s. Return a JSON object with "subject" (max 60 chars) and "body" (max 200 words). Only the JSON object.`, productName, features)
	raw, err := c.chatCompletion(ctx, prompt, 400)
	if err != nil {
		return "", "", err
	}
	var res struct {
		Subject string `json:"subject"`
		Body    string `json:"body"`
	}
	if err := json.Unmarshal([]byte(raw), &res); err != nil {
		return productName, raw, nil
	}
	return res.Subject, res.Body, nil
}
EOF

# ─── 7. Actualizar servidor principal ──────────────────────────
cat > internal/server/server.go <<'EOF'
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
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/domain"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/handler"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/middleware"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/openai"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/repository"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/service"
)

func Run(cfg *config.Config) {
	// 1. Database
	if err := db.InitDB(cfg.DatabaseURL); err != nil {
		log.Fatalf("DB init: %v", err)
	}

	// 2. Repositories
	productRepo := repository.NewProductRepo(db.DB)
	departmentRepo := repository.NewDepartmentRepo(db.DB)

	// 3. Services
	productSvc := service.NewProductService(productRepo)
	aiClient := openai.NewClient(cfg.OpenAIKey, cfg.OpenAIURL, cfg.OpenAIModel)
	aiSvc := service.NewAIService(aiClient)

	// 4. Handlers (versioned API)
	productH := handler.NewProductHandler(productSvc)
	deptH := handler.NewDepartmentHandler(departmentRepo)
	genH := handler.NewGenerateHandler(aiSvc)
	transH := handler.NewTranslateHandler(aiSvc)
	emailH := handler.NewEmailHandler(aiSvc)

	mux := http.NewServeMux()

	// Health
	mux.HandleFunc("/health", handler.HealthCheck())

	// API v1
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

	// Middleware chain
	allowedOrigins := []string{"http://localhost:5173"} // adjust
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
EOF

# ─── 8. Actualizar main.go ─────────────────────────────────────
cat > cmd/server/main.go <<'EOF'
package main

import (
	"log"
	"os"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/config"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/server"
)

func main() {
	if os.Getenv("OPENAI_API_KEY") == "" && os.Getenv("ENV") != "mock" {
		log.Fatal("OPENAI_API_KEY environment variable is required")
	}
	cfg := config.Load()
	server.Run(cfg)
}
EOF

# ─── 9. Añadir dependencias ─────────────────────────────────────
echo "📦 Instalando nuevas dependencias Go..."
go get github.com/lib/pq
go get github.com/sony/gobreaker
go mod tidy

echo ""
echo "✅ Mejoras aplicadas. Revisa los cambios y ejecuta 'docker-compose up --build' para probar."
echo "   Se creó un backup en: $BACKUP_DIR"