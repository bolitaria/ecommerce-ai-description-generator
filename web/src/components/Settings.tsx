export default function Settings() {
  return (
    <div style={{ background: 'white', borderRadius: '12px', padding: '2rem', boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
      <h2 style={{ color: 'var(--primary)', marginBottom: '1rem' }}>Store Settings</h2>
      <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
        {[
          ['Store Name', 'My Awesome Store'],
          ['Currency', 'USD'],
          ['Shipping Zones', 'North America, Europe'],
          ['Store Email', 'seller@example.com'],
        ].map(([label, value]) => (
          <div key={label} style={{ background: '#f8fafc', padding: '1rem', borderRadius: '8px' }}>
            <strong>{label}:</strong> {value}
          </div>
        ))}
      </div>
    </div>
  )
}
