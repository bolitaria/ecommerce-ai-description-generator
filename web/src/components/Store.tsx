import { useQuery } from '@tanstack/react-query'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { useCart } from '../context/CartContext'
import { useCompare } from '../context/CompareContext'
import SkeletonCard from './SkeletonCard'
import ShareButtons from './ShareButtons'
import './Store.css'

const API_URL = import.meta.env.VITE_API_URL || ''

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
  fetch(`${API_URL}/api/v1/departments`).then(res => res.json()).then(data => data.departments || [])

const fetchProducts = (params: URLSearchParams) =>
  fetch(`${API_URL}/api/v1/products?${params}`).then(res => res.json())

export default function Store() {
  const navigate = useNavigate()
  const { dispatch } = useCart()
  const { compareItems, toggleCompare } = useCompare()
  const [searchParams, setSearchParams] = useSearchParams()
  const page = parseInt(searchParams.get('page') || '1', 10)
  const search = searchParams.get('search') || ''
  const departmentId = searchParams.get('department_id') || ''

  const queryParams = new URLSearchParams()
  if (search) queryParams.set('search', search)
  if (departmentId) queryParams.set('department_id', departmentId)
  queryParams.set('page', String(page))
  queryParams.set('limit', '12')

  const { data: departments = [] } = useQuery<Department[]>({
    queryKey: ['departments'],
    queryFn: fetchDepartments,
  })

  const { data, isLoading } = useQuery({
    queryKey: ['products', page, search, departmentId],
    queryFn: () => fetchProducts(queryParams),
  })

  const products: Product[] = data?.data || []
  const totalPages = Math.ceil((data?.total || 0) / 12)

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

  return (
    <div>
      <header className="public-header">
        <div className="logo" onClick={() => navigate('/')}>Mi Tienda</div>
        <nav className="header-actions">
          <button onClick={() => navigate('/admin/dashboard')} className="admin-btn">🔑 Admin</button>
        </nav>
      </header>

      <div className="store-container">
        <div className="store-filters">
          <select value={departmentId} onChange={e => updateFilter('department_id', e.target.value)}>
            <option value="">Todas las categorías</option>
            {departments.map((d: Department) => (
              <option key={d.id} value={d.id}>{d.name}</option>
            ))}
          </select>
          <input
            type="text"
            placeholder="Buscar productos..."
            value={search}
            onChange={e => updateFilter('search', e.target.value)}
          />
        </div>

        {isLoading ? (
          <div className="store-grid">
            {Array.from({ length: 12 }).map((_, i) => <SkeletonCard key={i} />)}
          </div>
        ) : (
          <div className="store-grid">
            {products.map(product => (
              <div key={product.id} className="store-card">
                <div className="store-card-image" onClick={() => navigate(`/product/${product.id}`)}>
                  {product.image_url ? (
                    <img src={product.image_url} alt={product.name} />
                  ) : (
                    <span className="placeholder-img">{product.name.charAt(0).toUpperCase()}</span>
                  )}
                </div>
                <div className="store-card-body">
                  <h3 onClick={() => navigate(`/product/${product.id}`)}>{product.name}</h3>
                  <p className="store-card-features">{product.features}</p>
                  <p className="store-card-price">${product.price.toFixed(2)}</p>
                  <p className="store-card-desc">
                    {product.description ? product.description.slice(0, 80) + '…' : <em>Sin descripción</em>}
                  </p>
                  <div className="store-card-actions">
                    <button className="store-card-btn" onClick={(e) => { e.stopPropagation(); dispatch({ type: 'ADD', item: { id: product.id, name: product.name, price: product.price, image_url: product.image_url } }) }}>
                      🛒 Añadir
                    </button>
                    <button className="store-card-btn compare" onClick={(e) => { e.stopPropagation(); toggleCompare(product.id) }}>
                      {compareItems.includes(product.id) ? '✅ Comparando' : '⇆ Comparar'}
                    </button>
                    <ShareButtons product={product} />
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {!isLoading && products.length === 0 && (
          <div className="store-empty">No se encontraron productos.</div>
        )}

        <div className="store-pagination">
          <button disabled={page <= 1} onClick={() => setSearchParams(prev => { prev.set('page', String(page - 1)); return prev })}>Anterior</button>
          <span>Página {page} de {totalPages || 1}</span>
          <button disabled={page >= totalPages} onClick={() => setSearchParams(prev => { prev.set('page', String(page + 1)); return prev })}>Siguiente</button>
        </div>
      </div>
    </div>
  )
}