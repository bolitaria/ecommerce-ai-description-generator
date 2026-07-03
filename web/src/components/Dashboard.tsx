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
    orders: 142,   // mock
    revenue: 4280, // mock
  }
}

export default function Dashboard() {
  const { data, isLoading } = useQuery<Stats>({
    queryKey: ['stats'],
    queryFn: fetchStats,
  })

  return (
    <div style={{ background: 'white', padding: '2rem', borderRadius: '12px', boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
      <h2 style={{ color: 'var(--primary)' }}>Welcome back, Seller!</h2>
      <div style={{ display: 'flex', gap: '2rem', marginTop: '1.5rem', flexWrap: 'wrap' }}>
        <div style={{ background: '#f9f9f9', padding: '1.5rem', borderRadius: '8px', flex: 1, minWidth: '150px' }}>
          <h3>Products</h3>
          <p style={{ fontSize: '2rem', fontWeight: 'bold' }}>
            {isLoading ? '...' : data?.products}
          </p>
        </div>
        <div style={{ background: '#f9f9f9', padding: '1.5rem', borderRadius: '8px', flex: 1, minWidth: '150px' }}>
          <h3>Departments</h3>
          <p style={{ fontSize: '2rem', fontWeight: 'bold' }}>
            {isLoading ? '...' : data?.departments}
          </p>
        </div>
        <div style={{ background: '#f9f9f9', padding: '1.5rem', borderRadius: '8px', flex: 1, minWidth: '150px' }}>
          <h3>Orders</h3>
          <p style={{ fontSize: '2rem', fontWeight: 'bold' }}>
            {isLoading ? '...' : data?.orders}
          </p>
        </div>
        <div style={{ background: '#f9f9f9', padding: '1.5rem', borderRadius: '8px', flex: 1, minWidth: '150px' }}>
          <h3>Revenue</h3>
          <p style={{ fontSize: '2rem', fontWeight: 'bold' }}>
            ${isLoading ? '...' : data?.revenue?.toLocaleString()}
          </p>
        </div>
      </div>
    </div>
  )
}
