package service

import (
	"context"
	"fmt"
	"log"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/domain"
)

type ProductService struct {
	repo domain.ProductRepository
	ai   domain.AIGenerator
}

func NewProductService(repo domain.ProductRepository, ai domain.AIGenerator) *ProductService {
	return &ProductService{repo: repo, ai: ai}
}

func (s *ProductService) List(f domain.ProductFilter, page, limit int) ([]domain.Product, int, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}
	return s.repo.List(f, page, limit)
}

func (s *ProductService) Create(p domain.Product) (int, error) {
	if p.Name == "" || p.Features == "" {
		return 0, domain.ErrValidation("name and features required")
	}

	if p.Description == "" && s.ai != nil {
		desc, err := s.ai.GenerateDescription(context.Background(), p.Name, p.Features)
		if err != nil {
			log.Printf("AI generation failed for product %q: %v", p.Name, err)
		} else {
			p.Description = desc
		}
	}

	return s.repo.Create(p)
}

func (s *ProductService) Update(p domain.Product) error {
	return s.repo.Update(p)
}

func (s *ProductService) Delete(id int) error {
	return s.repo.Delete(id)
}

func (s *ProductService) GetByID(id int) (domain.Product, error) {
	return s.repo.GetByID(id)
}

func (s *ProductService) ImportFromRecords(records []domain.Product) (int, []error) {
	created := 0
	var errs []error
	for i, p := range records {
		id, err := s.Create(p)
		if err != nil {
			errs = append(errs, fmt.Errorf("fila %d: %w", i+2, err))
			continue
		}
		created++
		_ = id
	}
	return created, errs
}