package domain

type Product struct {
	ID           int     `json:"id"`
	Name         string  `json:"name"`
	Features     string  `json:"features"`
	Description  string  `json:"description"`
	DepartmentID int     `json:"department_id"`
	ImageURL     string  `json:"image_url"`
	Price        float64 `json:"price"`
}

type ProductFilter struct {
	DepartmentID *int
	Search       string
}

type ProductRepository interface {
	List(filter ProductFilter, page, limit int) ([]Product, int, error)
	GetByID(id int) (Product, error)
	Create(p Product) (int, error)
	Update(p Product) error
	Delete(id int) error
}