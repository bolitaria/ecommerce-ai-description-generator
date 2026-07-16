#!/bin/bash
# ==============================================
# Actualización final: traducción, UI y mock
# ==============================================

# 1. Actualizar mock de DeepSeek (soporte para English)
cat > cmd/mockopenai/main.go << 'EOF'
package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"regexp"
	"strings"
)

type mockResponse struct {
	Choices []struct {
		Message struct {
			Content string `json:"content"`
		} `json:"message"`
	} `json:"choices"`
}

func main() {
	http.HandleFunc("/v1/chat/completions", func(w http.ResponseWriter, r *http.Request) {
		bodyBytes, _ := io.ReadAll(r.Body)
		var req map[string]interface{}
		json.Unmarshal(bodyBytes, &req)

		messages := req["messages"].([]interface{})
		userMsg := messages[0].(map[string]interface{})["content"].(string)

		var content string
		switch {
		case strings.Contains(userMsg, "Translate the following text"):
			content = mockTranslate(userMsg)
		case strings.Contains(userMsg, "marketing email"):
			content = mockEmail(userMsg)
		default:
			content = mockDescription(userMsg)
		}

		resp := mockResponse{
			Choices: []struct {
				Message struct {
					Content string `json:"content"`
				} `json:"message"`
			}{
				{Message: struct {
					Content string `json:"content"`
				}{Content: content}},
			},
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(resp)
	})
	log.Println("Mock DeepSeek listening on :5000")
	http.ListenAndServe(":5000", nil)
}

func mockTranslate(prompt string) string {
	lang := "Spanish"
	text := ""
	if idx := strings.Index(prompt, "Translate the following text to "); idx != -1 {
		start := idx + len("Translate the following text to ")
		end := strings.Index(prompt[start:], ".")
		if end != -1 {
			lang = prompt[start : start+end]
		}
	}
	parts := strings.Split(prompt, "\n\n")
	if len(parts) > 1 {
		text = strings.TrimSpace(parts[len(parts)-1])
	}
	if text == "" {
		text = "(no text)"
	}
	switch lang {
	case "Spanish":
		return "[ES] " + text + " (traducción simulada)"
	case "French":
		return "[FR] " + text + " (traduction simulée)"
	case "German":
		return "[DE] " + text + " (simulierte Übersetzung)"
	case "English":
		return "[EN] " + text + " (simulated translation)"
	default:
		return fmt.Sprintf("[%s] %s", lang, text)
	}
}

func mockEmail(prompt string) string {
	name, feat := extractInfo(prompt)
	return fmt.Sprintf(`{"subject":"Novedad: %s ya disponible","body":"Hola,\n\nTe presentamos nuestro nuevo producto: %s.\n\n%s\n\n¡Pídelo ahora con un 10%% de descuento!\n\nSaludos,\nTu tienda de confianza"}`, name, name, feat)
}

func mockDescription(prompt string) string {
	name, feat := extractInfo(prompt)
	templates := []string{
		fmt.Sprintf("%s es la elección perfecta. %s. Fabricado con materiales de primera calidad y un diseño pensado para durar.", name, feat),
		fmt.Sprintf("Descubre %s. %s. Una combinación ideal de funcionalidad y estilo, adecuado para cualquier ocasión.", name, feat),
		fmt.Sprintf("%s marca la diferencia. %s. Innovación y confort en un solo producto. Supera tus expectativas.", name, feat),
	}
	return templates[len(name)%len(templates)]
}

func extractInfo(prompt string) (string, string) {
	name := "Producto"
	features := "características excepcionales"
	re := regexp.MustCompile(`for '([^']+)'`)
	if matches := re.FindStringSubmatch(prompt); len(matches) > 1 {
		name = matches[1]
	}
	if idx := strings.Index(prompt, "Key features:"); idx != -1 {
		start := idx + len("Key features:")
		featuresPart := strings.TrimSpace(prompt[start:])
		if end := strings.Index(featuresPart, "."); end != -1 {
			features = strings.TrimSpace(featuresPart[:end])
		} else {
			features = featuresPart
		}
	}
	return name, features
}
EOF

# 2. Reemplazar Products.tsx (versión final con traducción arreglada)
cat > web/src/components/Products.tsx << 'EOF'
import { useState, useRef } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useSearchParams } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import toast from 'react-hot-toast'
import SkeletonCard from './SkeletonCard'
import './Products.css'

const API_URL = import.meta.env.VITE_API_URL || ''

const productSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  features: z.string().min(1, 'Features required'),
  department_id: z.number().int().positive(),
  image_url: z.string().url().optional().or(z.literal('')),
  price: z.number().min(0).default(0),
})

type ProductForm = z.infer<typeof productSchema>

interface Product {
  id: number
  name: string
  features: string
  description: string
  department_id: number
  image_url?: string
  price: number
}

interface Department {
  id: number
  name: string
}

const fetchDepartments = () =>
  fetch(`${API_URL}/api/v1/departments`).then(res => res.json().then(data => data.departments || []))

const fetchProducts = (params: URLSearchParams) =>
  fetch(`${API_URL}/api/v1/products?${params}`).then(res => res.json())

export default function Products() {
  const queryClient = useQueryClient()
  const [searchParams, setSearchParams] = useSearchParams()
  const page = parseInt(searchParams.get('page') || '1', 10)
  const search = searchParams.get('search') || ''
  const departmentId = searchParams.get('department_id') || ''

  const [translateProduct, setTranslateProduct] = useState<Product | null>(null)
  const [translatedText, setTranslatedText] = useState('')
  const [emailModal, setEmailModal] = useState<{ subject: string; body: string } | null>(null)
  const [previewProduct, setPreviewProduct] = useState<Product | null>(null)
  const [editingId, setEditingId] = useState<number | null>(null)

  const fileInputRef = useRef<HTMLInputElement>(null)
  const [excelFile, setExcelFile] = useState<File | null>(null)
  const [excelPreview, setExcelPreview] = useState<Product[] | null>(null)

  const { data: departments = [] } = useQuery<Department[]>({
    queryKey: ['departments'],
    queryFn: fetchDepartments,
  })

  const queryParams = new URLSearchParams()
  if (search) queryParams.set('search', search)
  if (departmentId) queryParams.set('department_id', departmentId)
  queryParams.set('page', String(page))
  queryParams.set('limit', '6')

  const { data, isLoading } = useQuery({
    queryKey: ['products', page, search, departmentId],
    queryFn: () => fetchProducts(queryParams),
  })

  const { register, handleSubmit, reset, formState: { errors } } = useForm<ProductForm>({
    resolver: zodResolver(productSchema),
    defaultValues: { department_id: 1, image_url: '', price: 0 },
  })

  const addMutation = useMutation({
    mutationFn: (newProduct: ProductForm) =>
      fetch(`${API_URL}/api/v1/products`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newProduct),
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] })
      reset()
      toast.success('Producto añadido')
    },
    onError: () => toast.error('Error al añadir producto'),
  })

  const updateMutation = useMutation({
    mutationFn: (product: Product) =>
      fetch(`${API_URL}/api/v1/products/${product.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(product),
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] })
      setEditingId(null)
      toast.success('Producto actualizado')
    },
    onError: () => toast.error('Error al actualizar'),
  })

  const generateMutation = useMutation({
    mutationFn: (product: Product) =>
      fetch(`${API_URL}/api/v1/generate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ product_name: product.name, features: product.features }),
      }).then(res => res.json()),
    onSuccess: (data, product) => {
      updateMutation.mutate({ ...product, description: data.description })
      toast.success('Descripción generada')
    },
    onError: () => toast.error('Fallo en generación'),
  })

  const translateMutation = useMutation({
    mutationFn: ({ text, lang }: { text: string; lang: string }) =>
      fetch(`${API_URL}/api/v1/translate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text, target_lang: lang }),
      }).then(res => res.json()),
    onSuccess: (data) => setTranslatedText(data.translated),
    onError: () => toast.error('Fallo en traducción'),
  })

  const emailMutation = useMutation({
    mutationFn: (product: Product) =>
      fetch(`${API_URL}/api/v1/email`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ product_name: product.name, features: product.features }),
      }).then(res => res.json()),
    onSuccess: (data) => setEmailModal(data),
    onError: () => toast.error('Fallo en generación de email'),
  })

  const previewExcelMutation = useMutation({
    mutationFn: (file: File) => {
      const formData = new FormData()
      formData.append('file', file)
      return fetch(`${API_URL}/api/v1/products/import/preview`, {
        method: 'POST',
        body: formData,
      }).then(res => res.json())
    },
    onSuccess: (data) => setExcelPreview(data.preview || []),
    onError: () => toast.error('Error al leer Excel'),
  })

  const importMutation = useMutation({
    mutationFn: (file: File) => {
      const formData = new FormData()
      formData.append('file', file)
      return fetch(`${API_URL}/api/v1/products/import`, {
        method: 'POST',
        body: formData,
      }).then(res => res.json())
    },
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: ['products'] })
      setExcelPreview(null)
      setExcelFile(null)
      toast.success(`${data.created} productos importados`)
      if (data.errors > 0) toast.error(`${data.errors} filas fallaron`)
    },
    onError: () => toast.error('Fallo en importación'),
  })

  const generateAllMissing = useMutation({
    mutationFn: async () => {
      const products = data?.data || []
      const withoutDesc = products.filter((p: Product) => !p.description)
      for (const p of withoutDesc) {
        const res = await fetch(`${API_URL}/api/v1/generate`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ product_name: p.name, features: p.features }),
        })
        const result = await res.json()
        if (result.description) {
          await fetch(`${API_URL}/api/v1/products/${p.id}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ ...p, description: result.description }),
          })
        }
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] })
      toast.success('Descripciones generadas')
    },
    onError: () => toast.error('Fallo en la generación por lotes'),
  })

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) {
      setExcelFile(file)
      previewExcelMutation.mutate(file)
    }
  }

  const confirmImport = () => {
    if (excelFile) importMutation.mutate(excelFile)
  }

  const updateFilter = (key: string, value: string) => {
    const params = new URLSearchParams(searchParams)
    if (value) {
      params.set(key, value)
    } else {
      params.delete(key)
    }
    params.set('page', '1')
    setSearchParams(params)
  }

  const products: Product[] = data?.data || []
  const totalPages = Math.ceil((data?.total || 0) / 6)

  return (
    <div className="products-container">
      <div className="add-product-section">
        <h3>Añadir nuevo producto</h3>
        <form className="add-product-form" onSubmit={handleSubmit(data => addMutation.mutate(data))}>
          <div className="input-group">
            <input {...register('name')} placeholder=" " id="name" />
            <label htmlFor="name">Nombre del producto</label>
            {errors.name && <span className="error">{errors.name.message}</span>}
          </div>
          <div className="input-group">
            <input {...register('features')} placeholder=" " id="features" />
            <label htmlFor="features">Características clave</label>
            {errors.features && <span className="error">{errors.features.message}</span>}
          </div>
          <div className="input-group">
            <input {...register('image_url')} placeholder=" " id="image_url" />
            <label htmlFor="image_url">URL de imagen (opcional)</label>
          </div>
          <div className="input-group">
            <input type="number" step="0.01" {...register('price', { valueAsNumber: true })} placeholder=" " id="price" />
            <label htmlFor="price">Precio</label>
          </div>
          <div className="input-group">
            <select {...register('department_id', { valueAsNumber: true })} id="department">
              {departments.map((d: Department) => <option key={d.id} value={d.id}>{d.name}</option>)}
            </select>
            <label htmlFor="department">Departamento</label>
          </div>
          <button type="submit" className="btn-primary" disabled={addMutation.isPending}>
            Añadir producto
          </button>
          <small className="hint">Si no escribes descripción, la IA la generará automáticamente.</small>
        </form>
      </div>

      <div className="filters">
        <select value={departmentId} onChange={e => updateFilter('department_id', e.target.value)}>
          <option value="">Todos los departamentos</option>
          {departments.map((d: Department) => <option key={d.id} value={d.id}>{d.name}</option>)}
        </select>
        <input
          placeholder="Buscar..."
          value={search}
          onChange={e => updateFilter('search', e.target.value)}
        />
      </div>

      <div className="import-section">
        <input
          type="file"
          accept=".xlsx"
          ref={fileInputRef}
          style={{ display: 'none' }}
          onChange={handleFileChange}
        />
        <button onClick={() => fileInputRef.current?.click()} className="btn-primary">
          📥 Importar Excel
        </button>
        <a href={`${API_URL}/api/v1/products/import/template`} className="template-link" download>
          📄 Descargar plantilla
        </a>
        <button
          className="btn-generate"
          onClick={() => generateAllMissing.mutate()}
          disabled={generateAllMissing.isPending}
        >
          {generateAllMissing.isPending ? 'Generando...' : '🚀 Generar todas las descripciones'}
        </button>
      </div>

      {excelPreview && (
        <div className="excel-preview">
          <h4>Previsualización ({excelPreview.length} filas mostradas)</h4>
          <table>
            <thead>
              <tr>
                <th>Nombre</th><th>Características</th><th>Dept. ID</th><th>Imagen</th><th>Precio</th>
              </tr>
            </thead>
            <tbody>
              {excelPreview.map((p, idx) => (
                <tr key={idx}>
                  <td>{p.name}</td><td>{p.features}</td><td>{p.department_id}</td><td>{p.image_url?.slice(0, 30) || '-'}</td><td>{p.price.toFixed(2)}</td>
                </tr>
              ))}
            </tbody>
          </table>
          <div className="preview-actions">
            <button onClick={confirmImport} disabled={importMutation.isPending}>
              {importMutation.isPending ? 'Importando...' : '✅ Confirmar importación'}
            </button>
            <button onClick={() => { setExcelPreview(null); setExcelFile(null) }}>Cancelar</button>
          </div>
        </div>
      )}

      {isLoading ? (
        <div className="product-grid">
          {Array.from({ length: 6 }).map((_, i) => <SkeletonCard key={i} />)}
        </div>
      ) : (
        <div className="product-grid">
          {products.map(product => (
            <div key={product.id} className="product-card">
              <div className="product-img-placeholder">
                {product.image_url ? (
                  <img src={product.image_url} alt={product.name} />
                ) : (
                  <span>{product.name.charAt(0).toUpperCase()}</span>
                )}
              </div>
              <div className="product-info">
                {editingId === product.id ? (
                  <EditProductForm
                    product={product}
                    departments={departments}
                    onSave={(updated) => updateMutation.mutate(updated)}
                    onCancel={() => setEditingId(null)}
                  />
                ) : (
                  <>
                    <h4>{product.name}</h4>
                    <p className="features">{product.features}</p>
                    <p className="description">{product.description || <em>Sin descripción</em>}</p>
                    <p className="price">${product.price.toFixed(2)}</p>
                    <div className="card-actions">
                      <button className="btn-generate" onClick={() => generateMutation.mutate(product)}>Generar</button>
                      <button className="btn-translate" onClick={() => setTranslateProduct(product)} disabled={!product.description}>Traducir</button>
                      <button className="btn-email" onClick={() => emailMutation.mutate(product)}>Email</button>
                      <button className="btn-preview" onClick={() => setPreviewProduct(product)}>Vista previa</button>
                      <button className="btn-edit" onClick={() => setEditingId(product.id)}>Editar</button>
                    </div>
                  </>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      <div className="pagination">
        <button disabled={page <= 1} onClick={() => setSearchParams(prev => { prev.set('page', String(page - 1)); return prev })}>Anterior</button>
        <span>Página {page} de {totalPages || 1}</span>
        <button disabled={page >= totalPages} onClick={() => setSearchParams(prev => { prev.set('page', String(page + 1)); return prev })}>Siguiente</button>
      </div>

      {/* Modal de traducción – idiomas fijos, incluido English */}
      {translateProduct && (
        <div className="modal-overlay" onClick={() => setTranslateProduct(null)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <h3>Traducir descripción</h3>
            <p><strong>{translateProduct.name}:</strong> {translateProduct.description}</p>
            <select
              defaultValue=""
              onChange={e => translateMutation.mutate({ text: translateProduct.description, lang: e.target.value })}
            >
              <option value="" disabled>Seleccionar idioma</option>
              <option value="English">English</option>
              <option value="Spanish">Español</option>
              <option value="French">Francés</option>
              <option value="German">Alemán</option>
            </select>
            {translatedText && <div className="result-box">{translatedText}</div>}
            <button onClick={() => { setTranslateProduct(null); setTranslatedText(''); }}>Cerrar</button>
          </div>
        </div>
      )}

      {/* Modal de email */}
      {emailModal && (
        <div className="modal-overlay" onClick={() => setEmailModal(null)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <h3>Email de marketing</h3>
            <p><strong>Asunto:</strong> {emailModal.subject}</p>
            <p><strong>Cuerpo:</strong> {emailModal.body}</p>
            <button onClick={() => setEmailModal(null)}>Cerrar</button>
          </div>
        </div>
      )}

      {/* Modal de vista previa */}
      {previewProduct && (
        <div className="modal-overlay" onClick={() => setPreviewProduct(null)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <h2>{previewProduct.name}</h2>
            {previewProduct.image_url && <img src={previewProduct.image_url} alt={previewProduct.name} style={{ maxWidth: '100%', borderRadius: '8px', marginBottom: '1rem' }} />}
            <p><strong>Características:</strong> {previewProduct.features}</p>
            <p><strong>Descripción:</strong> {previewProduct.description || 'Sin descripción'}</p>
            <p><strong>Precio:</strong> ${previewProduct.price.toFixed(2)}</p>
            <p><strong>Departamento ID:</strong> {previewProduct.department_id}</p>
            <button onClick={() => setPreviewProduct(null)} style={{ marginTop: '1rem' }}>Cerrar</button>
          </div>
        </div>
      )}
    </div>
  )
}

function EditProductForm({ product, departments, onSave, onCancel }: {
  product: Product
  departments: Department[]
  onSave: (p: Product) => void
  onCancel: () => void
}) {
  const [name, setName] = useState(product.name)
  const [features, setFeatures] = useState(product.features)
  const [description, setDescription] = useState(product.description)
  const [price, setPrice] = useState(product.price)
  const [departmentId, setDepartmentId] = useState(product.department_id)
  const [imageUrl, setImageUrl] = useState(product.image_url || '')

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    onSave({ ...product, name, features, description, price, department_id: departmentId, image_url: imageUrl })
  }

  return (
    <form onSubmit={handleSubmit} className="edit-product-form">
      <input value={name} onChange={e => setName(e.target.value)} required placeholder="Nombre" />
      <input value={features} onChange={e => setFeatures(e.target.value)} required placeholder="Características" />
      <textarea value={description} onChange={e => setDescription(e.target.value)} placeholder="Descripción (vacío → IA)" />
      <input type="number" step="0.01" value={price} onChange={e => setPrice(+e.target.value)} placeholder="Precio" />
      <select value={departmentId} onChange={e => setDepartmentId(+e.target.value)}>
        {departments.map(d => <option key={d.id} value={d.id}>{d.name}</option>)}
      </select>
      <input value={imageUrl} onChange={e => setImageUrl(e.target.value)} placeholder="URL de imagen" />
      <div className="edit-buttons">
        <button type="submit">Guardar</button>
        <button type="button" onClick={onCancel}>Cancelar</button>
      </div>
    </form>
  )
}
EOF

echo "✅ Archivos actualizados correctamente."
echo "👉 Ejecuta: docker-compose up -d --build"
