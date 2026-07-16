package handler

import (
	"fmt"
	"mime/multipart"
	"net/http"
	"strconv"
	"strings"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/domain"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/service"
	"github.com/xuri/excelize/v2"
)

type ImportHandler struct {
	svc *service.ProductService
}

func NewImportHandler(svc *service.ProductService) *ImportHandler {
	return &ImportHandler{svc: svc}
}

func (h *ImportHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/api/v1/products/import")
	switch {
	case path == "/preview" && r.Method == http.MethodPost:
		h.preview(w, r)
	case path == "/template" && r.Method == http.MethodGet:
		h.downloadTemplate(w, r)
	default:
		if r.Method == http.MethodPost {
			h.importProducts(w, r)
		} else {
			writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		}
	}
}

func (h *ImportHandler) importProducts(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseMultipartForm(10 << 20); err != nil {
		writeError(w, http.StatusBadRequest, "error reading file")
		return
	}
	file, _, err := r.FormFile("file")
	if err != nil {
		writeError(w, http.StatusBadRequest, "missing 'file' field")
		return
	}
	defer file.Close()

	products, err := parseExcel(file)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	created, errs := h.svc.ImportFromRecords(products)
	resp := map[string]interface{}{
		"created": created,
		"errors":  len(errs),
	}
	if len(errs) > 0 {
		errMsgs := make([]string, len(errs))
		for i, e := range errs {
			errMsgs[i] = e.Error()
		}
		resp["error_details"] = errMsgs
	}
	writeJSON(w, http.StatusOK, resp)
}

func (h *ImportHandler) preview(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseMultipartForm(10 << 20); err != nil {
		writeError(w, http.StatusBadRequest, "error reading file")
		return
	}
	file, _, err := r.FormFile("file")
	if err != nil {
		writeError(w, http.StatusBadRequest, "missing 'file' field")
		return
	}
	defer file.Close()

	products, err := parseExcel(file)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	// Devolver solo los primeros 20 para la previsualización
	preview := products
	if len(preview) > 20 {
		preview = preview[:20]
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{
		"total_rows": len(products),
		"preview":    preview,
	})
}

func (h *ImportHandler) downloadTemplate(w http.ResponseWriter, r *http.Request) {
	f := excelize.NewFile()
	sheet := "Sheet1"
	// Cabeceras
	headers := []string{"name", "features", "department_id", "image_url", "price"}
	for i, h := range headers {
		cell, _ := excelize.CoordinatesToCellName(i+1, 1)
		f.SetCellValue(sheet, cell, h)
	}
	// Datos de ejemplo
	examples := [][]interface{}{
		{"Camiseta clásica", "100% algodón, lavable a máquina", 1, "https://example.com/camiseta.jpg", 19.99},
		{"Auriculares Bluetooth", "Cancelación de ruido, 30h batería", 2, "", 59.99},
	}
	for i, row := range examples {
		for j, val := range row {
			cell, _ := excelize.CoordinatesToCellName(j+1, i+2)
			f.SetCellValue(sheet, cell, val)
		}
	}
	w.Header().Set("Content-Type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
	w.Header().Set("Content-Disposition", "attachment; filename=template.xlsx")
	if err := f.Write(w); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func parseExcel(file multipart.File) ([]domain.Product, error) {
	f, err := excelize.OpenReader(file)
	if err != nil {
		return nil, fmt.Errorf("invalid Excel file")
	}
	rows, err := f.GetRows(f.GetSheetName(0))
	if err != nil || len(rows) < 2 {
		return nil, fmt.Errorf("file must have at least a header row and one data row")
	}

	var products []domain.Product
	for i, row := range rows {
		if i == 0 {
			continue // saltar cabecera
		}
		if len(row) < 3 {
			continue
		}
		depID, err := strconv.Atoi(row[2])
		if err != nil {
			continue
		}
		p := domain.Product{
			Name:         row[0],
			Features:     row[1],
			DepartmentID: depID,
		}
		if len(row) > 3 && row[3] != "" {
			p.ImageURL = row[3]
		}
		if len(row) > 4 && row[4] != "" {
			price, err := strconv.ParseFloat(row[4], 64)
			if err == nil {
				p.Price = price
			}
		}
		products = append(products, p)
	}
	return products, nil
}