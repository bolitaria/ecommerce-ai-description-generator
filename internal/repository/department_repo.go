package repository
import (
	"database/sql"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/domain"
)
type departmentRepo struct{ db *sql.DB }
func NewDepartmentRepo(db *sql.DB) domain.DepartmentRepository { return &departmentRepo{db} }
func (r *departmentRepo) ListAll() ([]domain.Department, error) {
	rows, err := r.db.Query("SELECT id, name FROM departments ORDER BY name")
	if err != nil { return nil, err }
	defer rows.Close()
	var deps []domain.Department
	for rows.Next() {
		var d domain.Department
		if err := rows.Scan(&d.ID, &d.Name); err != nil { return nil, err }
		deps = append(deps, d)
	}
	return deps, nil
}
