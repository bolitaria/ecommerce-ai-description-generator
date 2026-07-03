package handler

import (
	"net/http"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/domain"
)

type DepartmentHandler struct {
	repo domain.DepartmentRepository
}

func NewDepartmentHandler(repo domain.DepartmentRepository) *DepartmentHandler {
	return &DepartmentHandler{repo: repo}
}

func (h *DepartmentHandler) List(w http.ResponseWriter, r *http.Request) {
	deps, err := h.repo.ListAll()
	if err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"departments": deps})
}
