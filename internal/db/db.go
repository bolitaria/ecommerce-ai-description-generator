package db

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"path/filepath"

	_ "github.com/lib/pq"
)

var DB *sql.DB

func InitDB(databaseURL string) error {
	var err error
	DB, err = sql.Open("postgres", databaseURL)
	if err != nil {
		return fmt.Errorf("open db: %w", err)
	}
	if err = DB.Ping(); err != nil {
		return fmt.Errorf("ping db: %w", err)
	}
	if err = runMigrations(); err != nil {
		return fmt.Errorf("migrate: %w", err)
	}
	log.Println("Database initialized (PostgreSQL)")
	return nil
}

func runMigrations() error {
	// Usar ruta absoluta por defecto; puede sobrescribirse con MIGRATIONS_PATH
	migrationPath := os.Getenv("MIGRATIONS_PATH")
	if migrationPath == "" {
		migrationPath = "/db/migrations"
	}

	files, err := os.ReadDir(migrationPath)
	if err != nil {
		return fmt.Errorf("reading migrations dir %s: %w", migrationPath, err)
	}
	for _, f := range files {
		if !f.IsDir() && filepath.Ext(f.Name()) == ".sql" {
			content, err := os.ReadFile(filepath.Join(migrationPath, f.Name()))
			if err != nil {
				return err
			}
			if _, err := DB.Exec(string(content)); err != nil {
				return fmt.Errorf("executing %s: %w", f.Name(), err)
			}
			log.Printf("Applied migration: %s", f.Name())
		}
	}
	return nil
}
