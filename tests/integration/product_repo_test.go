package integration

import (
	"database/sql"
	"os"
	"testing"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/domain"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/repository"
	_ "github.com/lib/pq"
)

func setupDB(t *testing.T) *sql.DB {
	dsn := os.Getenv("TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("TEST_DATABASE_URL not set, skipping integration test")
	}
	db, err := sql.Open("postgres", dsn)
	if err != nil {
		t.Fatalf("open db: %v", err)
	}
	// Run migrations
	migrateFile := "../../db/migrations/000001_init.up.sql"
	content, err := os.ReadFile(migrateFile)
	if err != nil {
		t.Fatalf("read migration: %v", err)
	}
	if _, err := db.Exec(string(content)); err != nil {
		t.Fatalf("migrate: %v", err)
	}
	return db
}

func TestProductRepoCRUD(t *testing.T) {
	db := setupDB(t)
	defer db.Close()
	repo := repository.NewProductRepo(db)

	// Create
	id, err := repo.Create(domain.Product{Name: "TestProduct", Features: "f1", DepartmentID: 1})
	if err != nil {
		t.Fatalf("create: %v", err)
	}
	if id == 0 {
		t.Error("expected non-zero id")
	}
	// List
	prods, total, err := repo.List(domain.ProductFilter{}, 1, 10)
	if err != nil {
		t.Fatalf("list: %v", err)
	}
	if total < 1 {
		t.Error("expected at least one product")
	}
	found := false
	for _, p := range prods {
		if p.ID == id {
			found = true
			break
		}
	}
	if !found {
		t.Error("created product not found in list")
	}
	// Update
	err = repo.Update(domain.Product{ID: id, Name: "Updated", Features: "new", DepartmentID: 2})
	if err != nil {
		t.Fatalf("update: %v", err)
	}
	// Delete
	err = repo.Delete(id)
	if err != nil {
		t.Fatalf("delete: %v", err)
	}
}
