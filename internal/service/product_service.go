package service
import "github.com/bolitaria/ecommerce-ai-description-generator/internal/domain"
type ProductService struct { repo domain.ProductRepository }
func NewProductService(repo domain.ProductRepository) *ProductService { return &ProductService{repo} }
func (s *ProductService) List(f domain.ProductFilter, page, limit int) ([]domain.Product, int, error) {
	if page<1 { page=1 }; if limit<1||limit>100 { limit=10 }; return s.repo.List(f,page,limit)
}
func (s *ProductService) Create(p domain.Product) (int, error) {
	if p.Name==""||p.Features=="" { return 0,domain.ErrValidation("name and features required") }
	return s.repo.Create(p)
}
func (s *ProductService) Update(p domain.Product) error { return s.repo.Update(p) }
func (s *ProductService) Delete(id int) error { return s.repo.Delete(id) }
