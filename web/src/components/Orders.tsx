const orders = [
  { id: '#1001', product: 'Sticker Pack', status: 'Shipped' },
  { id: '#1002', product: 'Custom T-Shirt', status: 'Processing' },
  { id: '#1003', product: 'Mug 11oz', status: 'Pending' },
  { id: '#1004', product: 'Tote Bag', status: 'Shipped' },
  { id: '#1005', product: 'Phone Case', status: 'Processing' },
]

const statusColor = (s: string) =>
  s === 'Shipped' ? 'var(--success)' : s === 'Processing' ? 'var(--warning)' : '#94a3b8'

export default function Orders() {
  return (
    <div style={{ background: 'white', borderRadius: '12px', padding: '2rem', boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
      <h2 style={{ color: 'var(--primary)', marginBottom: '1rem' }}>Recent Orders</h2>
      <table style={{ width: '100%', borderCollapse: 'collapse' }}>
        <thead>
          <tr style={{ borderBottom: '1px solid var(--border)' }}>
            <th style={{ textAlign: 'left', padding: '0.75rem' }}>Order ID</th>
            <th style={{ textAlign: 'left', padding: '0.75rem' }}>Product</th>
            <th style={{ textAlign: 'left', padding: '0.75rem' }}>Status</th>
          </tr>
        </thead>
        <tbody>
          {orders.map(o => (
            <tr key={o.id} style={{ borderBottom: '1px solid var(--border)' }}>
              <td style={{ padding: '0.75rem' }}>{o.id}</td>
              <td style={{ padding: '0.75rem' }}>{o.product}</td>
              <td style={{ padding: '0.75rem', color: statusColor(o.status), fontWeight: 600 }}>{o.status}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
