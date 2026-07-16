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
	base := `FROM products p WHERE 1=1`
	args := []interface{}{}
	if filter.DepartmentID != nil {
		base += fmt.Sprintf(" AND p.department_id = $%d", len(args)+1)
		args = append(args, *filter.DepartmentID)
	}
	if filter.Search != "" {
		base += fmt.Sprintf(" AND p.name ILIKE $%d", len(args)+1)
		args = append(args, "%"+filter.Search+"%")
	}

	var total int
	countQuery := "SELECT COUNT(*) " + base
	if err := r.db.QueryRow(countQuery, args...).Scan(&total); err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * limit
	query := "SELECT id, name, features, description, department_id, COALESCE(image_url,''), COALESCE(price,0) " + base +
		" ORDER BY id DESC LIMIT $" + fmt.Sprintf("%d", len(args)+1) +
		" OFFSET $" + fmt.Sprintf("%d", len(args)+2)
	args = append(args, limit, offset)

	rows, err := r.db.Query(query, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var products []domain.Product
	for rows.Next() {
		var p domain.Product
		if err := rows.Scan(&p.ID, &p.Name, &p.Features, &p.Description, &p.DepartmentID, &p.ImageURL, &p.Price); err != nil {
			return nil, 0, err
		}
		products = append(products, p)
	}
	return products, total, nil
}

func (r *productRepo) Create(p domain.Product) (int, error) {
	var id int
	err := r.db.QueryRow(
		"INSERT INTO products (name, features, department_id, image_url, price) VALUES ($1,$2,$3,$4,$5) RETURNING id",
		p.Name, p.Features, p.DepartmentID, p.ImageURL, p.Price,
	).Scan(&id)
	return id, err
}

func (r *productRepo) Update(p domain.Product) error {
	_, err := r.db.Exec(
		"UPDATE products SET name=$1, features=$2, description=$3, department_id=$4, image_url=$5, price=$6 WHERE id=$7",
		p.Name, p.Features, p.Description, p.DepartmentID, p.ImageURL, p.Price, p.ID,
	)
	return err
}

func (r *productRepo) Delete(id int) error {
	_, err := r.db.Exec("DELETE FROM products WHERE id=$1", id)
	return err
}

func (r *productRepo) GetByID(id int) (domain.Product, error) {
	var p domain.Product
	err := r.db.QueryRow(
		"SELECT id, name, features, description, department_id, COALESCE(image_url,''), COALESCE(price,0) FROM products WHERE id=$1",
		id,
	).Scan(&p.ID, &p.Name, &p.Features, &p.Description, &p.DepartmentID, &p.ImageURL, &p.Price)
	return p, err
}