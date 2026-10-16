package config

import "os"

// AIProviderConfig holds the configuration of one AI provider in the fallback chain.
type AIProviderConfig struct {
	Name    string
	APIKey  string
	BaseURL string
	Model   string
}

type Config struct {
	Port          string
	DeepSeekKey   string
	DeepSeekURL   string
	DeepSeekModel string
	MaxTokens     int
	RateLimit     float64
	Environment   string
	DBPath        string
	DatabaseURL   string
	JWTSecret     string
	RedisURL      string

	// AIProviders is the ordered fallback chain.
	// Priority: Groq > Gemini > OpenRouter > DeepSeek.
	// Only providers with a non-empty API key are included.
	AIProviders []AIProviderConfig
}

func Load() *Config {
	c := &Config{
		Port:          getEnv("PORT", "8080"),
		DeepSeekKey:   os.Getenv("DEEPSEEK_API_KEY"),
		DeepSeekURL:   getEnv("DEEPSEEK_URL", "https://api.deepseek.com/v1"),
		DeepSeekModel: getEnv("DEEPSEEK_MODEL", "deepseek-chat"),
		MaxTokens:     300,
		RateLimit:     5.0,
		Environment:   getEnv("ENV", "development"),
		DBPath:        getEnv("DB_PATH", "./data/store.db"),
		DatabaseURL:   getEnv("DATABASE_URL", "postgres://user:pass@localhost:5432/store?sslmode=disable"),
		JWTSecret:     getEnv("JWT_SECRET", "dev-secret-change-me"),
		RedisURL:      getEnv("REDIS_URL", "redis://localhost:6379"),
	}
	c.AIProviders = buildProviderChain(c)
	return c
}

// buildProviderChain returns the ordered list of AI providers to try.
// Providers without an API key are skipped.
func buildProviderChain(c *Config) []AIProviderConfig {
	var chain []AIProviderConfig

	if key := os.Getenv("GROQ_API_KEY"); key != "" {
		chain = append(chain, AIProviderConfig{
			Name:    "groq",
			APIKey:  key,
			BaseURL: getEnv("GROQ_URL", "https://api.groq.com/openai/v1"),
			Model:   getEnv("GROQ_MODEL", "llama-3.3-70b-versatile"),
		})
	}

	if key := os.Getenv("GEMINI_API_KEY"); key != "" {
		chain = append(chain, AIProviderConfig{
			Name:    "gemini",
			APIKey:  key,
			BaseURL: getEnv("GEMINI_URL", "https://generativelanguage.googleapis.com/v1beta/openai"),
			Model:   getEnv("GEMINI_MODEL", "gemini-2.5-flash"),
		})
	}

	if key := os.Getenv("OPENROUTER_API_KEY"); key != "" {
		chain = append(chain, AIProviderConfig{
			Name:    "openrouter",
			APIKey:  key,
			BaseURL: getEnv("OPENROUTER_URL", "https://openrouter.ai/api/v1"),
			Model:   getEnv("OPENROUTER_MODEL", "qwen/qwen3-32b:free"),
		})
	}

	if c.DeepSeekKey != "" {
		chain = append(chain, AIProviderConfig{
			Name:    "deepseek",
			APIKey:  c.DeepSeekKey,
			BaseURL: c.DeepSeekURL,
			Model:   c.DeepSeekModel,
		})
	}

	return chain
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
