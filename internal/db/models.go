package db

import "time"

type Department struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
}

type Product struct {
	ID           int       `json:"id"`
	Name         string    `json:"name"`
	Features     string    `json:"features"`
	Description  string    `json:"description"`
	DepartmentID int       `json:"department_id"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}
