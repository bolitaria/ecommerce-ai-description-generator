package handler

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/db"
)

func ProductsHandler() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			getProducts(w, r)
		case http.MethodPost:
			createProduct(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	}
}

func ProductByIDHandler() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id, err := parseID(r.URL.Path, "/api/products/")
		if err != nil {
			http.Error(w, "invalid id", http.StatusBadRequest)
			return
		}
		switch r.Method {
		case http.MethodPut:
			updateProduct(w, r, id)
		case http.MethodDelete:
			deleteProduct(w, r, id)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	}
}

func getProducts(w http.ResponseWriter, r *http.Request) {
	query := `SELECT p.id, p.name, p.features, p.description, p.department_id,
	          p.created_at, p.updated_at, d.name as department_name
	          FROM products p JOIN departments d ON p.department_id = d.id WHERE 1=1`

	countQuery := `SELECT COUNT(*) FROM products p JOIN departments d ON p.department_id = d.id WHERE 1=1`

	departmentID := r.URL.Query().Get("department_id")
	search := r.URL.Query().Get("search")

	var args []interface{}
	if departmentID != "" {
		filter := " AND p.department_id = ?"
		query += filter
		countQuery += filter
		id, _ := strconv.Atoi(departmentID)
		args = append(args, id)
	}
	if search != "" {
		filter := " AND p.name LIKE ?"
		query += filter
		countQuery += filter
		args = append(args, "%"+search+"%")
	}

	var total int
	err := db.DB.QueryRow(countQuery, args...).Scan(&total)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	page, _ := strconv.Atoi(r.URL.Query().Get("page"))
	if page < 1 {
		page = 1
	}
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit < 1 || limit > 100 {
		limit = 10
	}
	offset := (page - 1) * limit

	query += " ORDER BY p.updated_at DESC LIMIT ? OFFSET ?"
	args = append(args, limit, offset)

	rows, err := db.DB.Query(query, args...)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var products []map[string]interface{}
	for rows.Next() {
		var id, depID int
		var name, features, description, depName string
		var createdAt, updatedAt string
		if err := rows.Scan(&id, &name, &features, &description, &depID, &createdAt, &updatedAt, &depName); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		products = append(products, map[string]interface{}{
			"id":              id,
			"name":            name,
			"features":        features,
			"description":     description,
			"department_id":   depID,
			"department_name": depName,
			"created_at":      createdAt,
			"updated_at":      updatedAt,
		})
	}

	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("X-Total-Count", strconv.Itoa(total))
	json.NewEncoder(w).Encode(products)
}

func createProduct(w http.ResponseWriter, r *http.Request) {
	var p struct {
		Name         string `json:"name"`
		Features     string `json:"features"`
		DepartmentID int    `json:"department_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}
	res, err := db.DB.Exec("INSERT INTO products (name, features, department_id) VALUES (?, ?, ?)",
		p.Name, p.Features, p.DepartmentID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	id, _ := res.LastInsertId()
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{"id": id})
}

func updateProduct(w http.ResponseWriter, r *http.Request, id int) {
	var p struct {
		Name         string `json:"name"`
		Features     string `json:"features"`
		Description  string `json:"description"`
		DepartmentID int    `json:"department_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}
	_, err := db.DB.Exec(`UPDATE products SET name=?, features=?, description=?, department_id=?, updated_at=CURRENT_TIMESTAMP WHERE id=?`,
		p.Name, p.Features, p.Description, p.DepartmentID, id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusOK)
}

func deleteProduct(w http.ResponseWriter, r *http.Request, id int) {
	_, err := db.DB.Exec("DELETE FROM products WHERE id=?", id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusOK)
}

func parseID(path, prefix string) (int, error) {
	idStr := strings.TrimPrefix(path, prefix)
	return strconv.Atoi(idStr)
}
