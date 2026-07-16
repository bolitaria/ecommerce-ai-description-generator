import { useQuery } from '@tanstack/react-query'
import { useParams, useNavigate } from 'react-router-dom'
import { useCart } from '../context/CartContext'
import ShareButtons from './ShareButtons'
import SkeletonCard from './SkeletonCard'

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

export default function ProductDetail() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { dispatch } = useCart()

  const { data: product, isLoading, isError } = useQuery<Product>({
    queryKey: ['product', id],
    queryFn: () => fetch(`${API_URL}/api/v1/products/${id}`).then(res => {
      if (!res.ok) throw new Error('Producto no encontrado')
      return res.json()
    }),
    retry: false,
  })

  if (isLoading) return <div className="store-loading"><SkeletonCard /></div>
  if (isError || !product) return (
    <div className="store-empty">
      <h2>Producto no encontrado</h2>
      <button onClick={() => navigate('/')}>Volver a la tienda</button>
    </div>
  )

  return (
    <div style={{ maxWidth: '700px', margin: '2rem auto', background: 'white', padding: '2rem', borderRadius: '12px', boxShadow: '0 4px 20px rgba(0,0,0,0.08)' }}>
      <button onClick={() => navigate(-1)} style={{ marginBottom: '1rem', background: 'none', border: 'none', color: 'var(--primary)', cursor: 'pointer', fontWeight: 600 }}>
        ← Volver
      </button>
      {product.image_url && (
        <img src={product.image_url} alt={product.name} style={{ width: '100%', maxHeight: '400px', objectFit: 'cover', borderRadius: '12px', marginBottom: '1.5rem' }} />
      )}
      <h1>{product.name}</h1>
      <p style={{ color: 'var(--text-light)', marginBottom: '0.5rem' }}>{product.features}</p>
      <p style={{ fontWeight: 700, fontSize: '2rem', color: 'var(--primary)', marginBottom: '1rem' }}>
        ${product.price.toFixed(2)}
      </p>
      <p style={{ lineHeight: 1.7, marginBottom: '1.5rem', whiteSpace: 'pre-wrap' }}>{product.description || 'No hay descripción disponible.'}</p>
      <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
        <button className="store-card-btn" onClick={() => dispatch({ type: 'ADD', item: { id: product.id, name: product.name, price: product.price, image_url: product.image_url } })}>
          🛒 Añadir al carrito
        </button>
        <ShareButtons product={product} />
      </div>
    </div>
  )
}