//go:build wireinject
// +build wireinject

package internal

import (
	"database/sql"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/domain"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/handler"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/openai"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/repository"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/service"
	"github.com/google/wire"
)

func InitializeServer(db *sql.DB, apiKey, apiURL, model string) (*handler.ProductHandler, *handler.DepartmentHandler, *handler.GenerateHandler, *handler.TranslateHandler, *handler.EmailHandler, error) {
	wire.Build(
		repository.NewProductRepo,
		repository.NewDepartmentRepo,
		service.NewProductService,
		openai.NewClient,
		service.NewAIService,
		handler.NewProductHandler,
		handler.NewDepartmentHandler,
		handler.NewGenerateHandler,
		handler.NewTranslateHandler,
		handler.NewEmailHandler,
	)
	return nil, nil, nil, nil, nil, nil
}
