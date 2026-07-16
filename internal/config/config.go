package config

import "os"

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
}

func Load() *Config {
	return &Config{
		Port:          getEnv("PORT", "8080"),
		DeepSeekKey:   os.Getenv("DeepSeek_API_KEY"),
		DeepSeekURL:   getEnv("DeepSeek_URL", "https://api.deepseek.com/v1"),
		DeepSeekModel: getEnv("DeepSeek_MODEL", "deepseek-chat"),
		MaxTokens:     300,
		RateLimit:     5.0,
		Environment:   getEnv("ENV", "development"),
		DBPath:        getEnv("DB_PATH", "./data/store.db"),
		DatabaseURL:   getEnv("DATABASE_URL", "postgres://user:pass@localhost:5432/store?sslmode=disable"),
		JWTSecret:     getEnv("JWT_SECRET", "dev-secret-change-me"),
		RedisURL:      getEnv("REDIS_URL", "redis://localhost:6379"),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}