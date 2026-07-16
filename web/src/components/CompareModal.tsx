import { useQuery } from '@tanstack/react-query'
import { useCompare } from '../context/CompareContext'
import './CompareModal.css'

const API_URL = import.meta.env.VITE_API_URL || ''

interface Product {
  id: number
  name: string
  features: string
  description: string
  price: number
}

export default function CompareModal() {
  const { compareItems, clearCompare } = useCompare()

  if (compareItems.length < 2) return null

  return (
    <div className="modal-overlay" onClick={clearCompare}>
      <div className="modal compare-modal" onClick={e => e.stopPropagation()}>
        <h2>Comparar productos</h2>
        <div className="compare-grid">
          {compareItems.map(id => (
            <CompareProductCard key={id} id={id} />
          ))}
        </div>
        <button className="btn-close" onClick={clearCompare}>Cerrar</button>
      </div>
    </div>
  )
}

function CompareProductCard({ id }: { id: number }) {
  const { data: product, isLoading } = useQuery<Product>({
    queryKey: ['product', id],
    queryFn: () => fetch(`${API_URL}/api/v1/products/${id}`).then(res => res.json()),
    staleTime: 60000,
  })

  if (isLoading) return <div className="compare-item">Cargando...</div>
  if (!product) return <div className="compare-item">Producto no encontrado</div>

  return (
    <div className="compare-item">
      <h4>{product.name}</h4>
      <p><strong>Características:</strong> {product.features}</p>
      <p className="price">${product.price.toFixed(2)}</p>
      <p className="desc">{product.description?.slice(0, 120)}…</p>
    </div>
  )
}