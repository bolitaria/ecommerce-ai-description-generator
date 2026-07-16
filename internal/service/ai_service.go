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