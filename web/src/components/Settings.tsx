export default function Settings() {
  return (
    <div style={{ background: 'white', padding: '2rem', borderRadius: '12px', boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
      <h2 style={{ color: 'var(--primary)' }}>Store Settings</h2>
      <p style={{ marginTop: '1rem' }}>Manage your store preferences.</p>
      <div style={{ marginTop: '2rem', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
        <div style={{ background: '#f9f9f9', padding: '1rem', borderRadius: '8px' }}>
          <strong>Store Name:</strong> My Awesome Store
        </div>
        <div style={{ background: '#f9f9f9', padding: '1rem', borderRadius: '8px' }}>
          <strong>Currency:</strong> USD
        </div>
        <div style={{ background: '#f9f9f9', padding: '1rem', borderRadius: '8px' }}>
          <strong>Shipping Zones:</strong> North America, Europe
        </div>
        <div style={{ background: '#f9f9f9', padding: '1rem', borderRadius: '8px' }}>
          <strong>Store Email:</strong> seller@example.com
        </div>
      </div>
    </div>
  )
}
