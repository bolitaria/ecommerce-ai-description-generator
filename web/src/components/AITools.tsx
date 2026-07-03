export default function AITools() {
  return (
    <div style={{ background: 'white', padding: '2rem', borderRadius: '12px', boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
      <h2 style={{ color: 'var(--primary)' }}>AI Content Tools</h2>
      <p style={{ marginTop: '1rem' }}>
        All AI features (generate description, translate, email) are available inside the Products section.
      </p>
      <p>
        Go to <a href="#" onClick={(e) => { e.preventDefault(); window.dispatchEvent(new CustomEvent('navigate', { detail: 'products' })) }} style={{ color: 'var(--primary)' }}>Products</a> and use the buttons on each product card.
      </p>
    </div>
  )
}
