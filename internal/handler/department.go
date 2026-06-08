package handler

import (
	"encoding/json"
	"net/http"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/db"
)

func GetDepartments() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		rows, err := db.DB.Query("SELECT id, name FROM departments ORDER BY name")
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		defer rows.Close()

		var deps []db.Department
		for rows.Next() {
			var d db.Department
			if err := rows.Scan(&d.ID, &d.Name); err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			deps = append(deps, d)
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(deps)
	}
}
