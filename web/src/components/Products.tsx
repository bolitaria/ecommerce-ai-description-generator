import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import toast from 'react-hot-toast'
import './Products.css'

const API_URL = import.meta.env.VITE_API_URL || ''

// Schemas
const productSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  features: z.string().min(1, 'Features required'),
  department_id: z.number().int().positive(),
})

type ProductForm = z.infer<typeof productSchema>

interface Product {
  id: number
  name: string
  features: string
  description: string
  department_id: number
  department_name?: string
}

interface Department {
  id: number
  name: string
}

const fetchDepartments = () =>
  fetch(`${API_URL}/api/v1/departments`).then(res => res.json().then(data => data.departments || []))

const fetchProducts = ({ page, limit, search, departmentId }: any) => {
  const params = new URLSearchParams()
  if (search) params.append('search', search)
  if (departmentId) params.append('department_id', departmentId)
  params.append('page', String(page))
  params.append('limit', String(limit))
  return fetch(`${API_URL}/api/v1/products?${params}`).then(res => res.json())
}

export default function Products() {
  const queryClient = useQueryClient()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [departmentFilter, setDepartmentFilter] = useState('')
  const [translateProduct, setTranslateProduct] = useState<Product | null>(null)
  const [translatedText, setTranslatedText] = useState('')
  const [emailModal, setEmailModal] = useState<{ subject: string; body: string } | null>(null)

  const { data: departments = [] } = useQuery<Department[]>({
    queryKey: ['departments'],
    queryFn: fetchDepartments,
  })

  const { data, isLoading, error } = useQuery({
    queryKey: ['products', page, search, departmentFilter],
    queryFn: () => fetchProducts({ page, limit: 6, search, departmentId: departmentFilter }),
  })

  const { register, handleSubmit, reset, formState: { errors } } = useForm<ProductForm>({
    resolver: zodResolver(productSchema),
    defaultValues: { department_id: 1 },
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
      toast.success('Product added')
    },
    onError: () => toast.error('Failed to add product'),
  })

  const generateMutation = useMutation({
    mutationFn: (product: Product) =>
      fetch(`${API_URL}/api/v1/generate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ product_name: product.name, features: product.features }),
      }).then(res => res.json()),
    onSuccess: (data, product) => {
      fetch(`${API_URL}/api/v1/products/${product.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...product, description: data.description }),
      })
      queryClient.invalidateQueries({ queryKey: ['products'] })
      toast.success('Description generated')
    },
    onError: () => toast.error('Generation failed'),
  })

  const translateMutation = useMutation({
    mutationFn: ({ text, lang }: { text: string; lang: string }) =>
      fetch(`${API_URL}/api/v1/translate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text, target_lang: lang }),
      }).then(res => res.json()),
    onSuccess: (data) => setTranslatedText(data.translated),
    onError: () => toast.error('Translation failed'),
  })

  const emailMutation = useMutation({
    mutationFn: (product: Product) =>
      fetch(`${API_URL}/api/v1/email`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ product_name: product.name, features: product.features }),
      }).then(res => res.json()),
    onSuccess: (data) => setEmailModal(data),
    onError: () => toast.error('Email generation failed'),
  })

  const products: Product[] = data?.data || []
  const totalPages = Math.ceil((data?.total || 0) / 6)

  return (
    <div className="products-container">
      <div className="add-product-section">
        <h3>Add New Product</h3>
        <form className="add-product-form" onSubmit={handleSubmit(data => addMutation.mutate(data))}>
          <input {...register('name')} placeholder="Product name" />
          {errors.name && <span className="error">{errors.name.message}</span>}
          <input {...register('features')} placeholder="Key features" />
          {errors.features && <span className="error">{errors.features.message}</span>}
          <select {...register('department_id', { valueAsNumber: true })}>
            {departments.map((d: Department) => <option key={d.id} value={d.id}>{d.name}</option>)}
          </select>
          <button type="submit" className="add-btn" disabled={addMutation.isPending}>Add</button>
        </form>
      </div>

      <div className="filters">
        <select value={departmentFilter} onChange={e => setDepartmentFilter(e.target.value)}>
          <option value="">All Departments</option>
          {departments.map((d: Department) => <option key={d.id} value={d.id}>{d.name}</option>)}
        </select>
        <input placeholder="Search..." value={search} onChange={e => setSearch(e.target.value)} />
      </div>

      {isLoading && <div>Loading...</div>}
      {error && <div className="error-banner">Failed to load products</div>}

      <div className="product-grid">
        {products.map(product => (
          <div key={product.id} className="product-card">
            <div className="product-img-placeholder"><span>{product.department_name}</span></div>
            <div className="product-info">
              <h4>{product.name}</h4>
              <p className="features">{product.features}</p>
              <p className="description">{product.description || <i>No description</i>}</p>
              <div className="card-actions">
                <button className="btn-generate" onClick={() => generateMutation.mutate(product)} disabled={generateMutation.isPending}>
                  {generateMutation.isPending ? '...' : 'Generate'}
                </button>
                <button className="btn-translate" onClick={() => setTranslateProduct(product)} disabled={!product.description}>
                  Translate
                </button>
                <button className="btn-email" onClick={() => emailMutation.mutate(product)}>
                  Email
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="pagination">
        <button disabled={page <= 1} onClick={() => setPage(p => p - 1)}>Previous</button>
        <span>Page {page} of {totalPages}</span>
        <button disabled={page >= totalPages} onClick={() => setPage(p => p + 1)}>Next</button>
      </div>

      {translateProduct && (
        <div className="modal-overlay" onClick={() => setTranslateProduct(null)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <h3>Translate Description</h3>
            <p><strong>{translateProduct.name}:</strong> {translateProduct.description}</p>
            <select defaultValue="" onChange={e => translateMutation.mutate({ text: translateProduct.description, lang: e.target.value })}>
              <option value="" disabled>Select language</option>
              <option value="Spanish">Spanish</option>
              <option value="French">French</option>
              <option value="German">German</option>
            </select>
            {translatedText && <div className="result-box">{translatedText}</div>}
            <button onClick={() => setTranslateProduct(null)}>Close</button>
          </div>
        </div>
      )}

      {emailModal && (
        <div className="modal-overlay" onClick={() => setEmailModal(null)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <h3>Marketing Email</h3>
            <p><strong>Subject:</strong> {emailModal.subject}</p>
            <p><strong>Body:</strong> {emailModal.body}</p>
            <button onClick={() => setEmailModal(null)}>Close</button>
          </div>
        </div>
      )}
    </div>
  )
}
