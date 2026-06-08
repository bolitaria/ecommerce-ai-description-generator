package db

import (
	"database/sql"
	"fmt"
	"log"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

func InitDB(path string) error {
	var err error
	DB, err = sql.Open("sqlite", path)
	if err != nil {
		return fmt.Errorf("open db: %w", err)
	}
	if err = DB.Ping(); err != nil {
		return fmt.Errorf("ping db: %w", err)
	}
	if err = migrate(); err != nil {
		return fmt.Errorf("migrate: %w", err)
	}
	seedDepartments()
	seedProducts()
	log.Println("Database initialized with demo data")
	return nil
}

func migrate() error {
	query := `
	CREATE TABLE IF NOT EXISTS departments (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT NOT NULL UNIQUE
	);
	CREATE TABLE IF NOT EXISTS products (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT NOT NULL,
		features TEXT NOT NULL,
		description TEXT DEFAULT '',
		department_id INTEGER NOT NULL,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (department_id) REFERENCES departments(id)
	);
	`
	_, err := DB.Exec(query)
	return err
}

func seedDepartments() {
	deps := []string{"Stickers", "Apparel", "Drinkware", "Home & Living", "Accessories"}
	for _, d := range deps {
		DB.Exec("INSERT OR IGNORE INTO departments (name) VALUES (?)", d)
	}
}

func seedProducts() {
	var count int
	DB.QueryRow("SELECT COUNT(*) FROM products").Scan(&count)
	if count > 0 {
		return
	}
	products := []struct {
		name         string
		features     string
		description  string
		departmentID int
	}{
		{"Sticker Pack", "Waterproof, UV-resistant, 5x5cm", "High-quality waterproof stickers perfect for outdoor use. Vibrant colors and durable material.", 1},
		{"Custom T-Shirt", "100% cotton, screen-printed, unisex", "Comfortable and stylish custom t-shirts. Perfect for events, teams, or personal expression.", 2},
		{"Mug 11oz", "Ceramic, dishwasher safe, vibrant print", "Start your day with a smile using our custom mugs. Microwave and dishwasher safe.", 3},
		{"Tote Bag", "Eco-friendly canvas, reinforced stitching", "Eco-friendly tote bags for everyday use. Spacious and durable.", 4},
		{"Phone Case", "Shock-absorbent TPU, wireless charging compatible", "Protect your phone in style with custom printed cases. Slim and protective.", 5},
		{"Hoodie", "Fleece lining, adjustable hood, kangaroo pocket", "Stay warm and trendy with our customizable hoodies. Soft and cozy.", 2},
	}
	for _, p := range products {
		DB.Exec("INSERT INTO products (name, features, description, department_id) VALUES (?, ?, ?, ?)",
			p.name, p.features, p.description, p.departmentID)
	}
}
