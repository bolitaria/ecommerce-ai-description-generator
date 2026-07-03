const orders = [
  { id: '#1001', product: 'Sticker Pack', status: 'Shipped' },
  { id: '#1002', product: 'Custom T-Shirt', status: 'Processing' },
  { id: '#1003', product: 'Mug 11oz', status: 'Pending' },
  { id: '#1004', product: 'Tote Bag', status: 'Shipped' },
  { id: '#1005', product: 'Phone Case', status: 'Processing' },
]

export default function Orders() {
  return (
    <div style={{ background: 'white', padding: '2rem', borderRadius: '12px', boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
      <h2 style={{ color: 'var(--primary)' }}>Recent Orders</h2>
      <table style={{ width: '100%', marginTop: '1rem', borderCollapse: 'collapse' }}>
        <thead>
          <tr>
            <th style={{ textAlign: 'left', padding: '0.5rem', borderBottom: '1px solid #ddd' }}>Order ID</th>
            <th style={{ textAlign: 'left', padding: '0.5rem', borderBottom: '1px solid #ddd' }}>Product</th>
            <th style={{ textAlign: 'left', padding: '0.5rem', borderBottom: '1px solid #ddd' }}>Status</th>
          </tr>
        </thead>
        <tbody>
          {orders.map((o) => (
            <tr key={o.id}>
              <td style={{ padding: '0.5rem' }}>{o.id}</td>
              <td style={{ padding: '0.5rem' }}>{o.product}</td>
              <td style={{ padding: '0.5rem', color: o.status === 'Shipped' ? 'green' : o.status === 'Processing' ? 'orange' : 'blue' }}>
                {o.status}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
