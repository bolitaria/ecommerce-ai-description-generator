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
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
