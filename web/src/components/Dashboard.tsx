import { useQuery } from '@tanstack/react-query'

const API_URL = import.meta.env.VITE_API_URL || ''

interface Stats {
  products: number
  departments: number
  orders: number
  revenue: number
}

const fetchStats = async (): Promise<Stats> => {
  const [prodRes, deptRes] = await Promise.all([
    fetch(`${API_URL}/api/v1/products?limit=1`),
    fetch(`${API_URL}/api/v1/departments`),
  ])
  const prodData = await prodRes.json()
  const deptData = await deptRes.json()
  return {
    products: prodData.total || 0,
    departments: (deptData.departments || []).length,
    orders: 142,
    revenue: 4280,
  }
}

export default function Dashboard() {
  const { data, isLoading } = useQuery<Stats>({
    queryKey: ['stats'],
    queryFn: fetchStats,
  })

  const cards = [
    { label: 'Productos', value: data?.products ?? '...', icon: '📦', color: '#0d9488' },
    { label: 'Departamentos', value: data?.departments ?? '...', icon: '🏷️', color: '#6366f1' },
    { label: 'Pedidos', value: data?.orders ?? '...', icon: '📋', color: '#f59e0b' },
    { label: 'Ingresos', value: `$${(data?.revenue ?? 0).toLocaleString()}`, icon: '💰', color: '#10b981' },
  ]

  return (
    <div>
      <h2 style={{ marginBottom: '1.5rem', color: 'var(--text)' }}>Bienvenido, Seller</h2>
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
        gap: '1.5rem'
      }}>
        {cards.map(({ label, value, icon, color }) => (
          <div key={label} style={{
            background: 'white',
            borderRadius: 'var(--radius)',
            padding: '1.8rem',
            boxShadow: 'var(--shadow-sm)',
            display: 'flex',
            alignItems: 'center',
            gap: '1.2rem',
            borderLeft: `4px solid ${color}`
          }}>
            <div style={{ fontSize: '2.5rem' }}>{icon}</div>
            <div>
              <p style={{ color: 'var(--text-light)', fontSize: '0.9rem', marginBottom: '0.3rem' }}>{label}</p>
              <p style={{ fontSize: '2rem', fontWeight: 700, color: 'var(--text)' }}>
                {isLoading ? '...' : value}
              </p>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
