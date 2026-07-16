#!/bin/bash

# 1. Estilos globales mejorados
cat > web/src/index.css << 'EOF'
:root {
  --primary: #0d9488;
  --primary-hover: #0f766e;
  --accent: #f97316;
  --accent-hover: #ea580c;
  --bg: #f8fafc;
  --sidebar-bg: #0f172a;
  --sidebar-text: #cbd5e1;
  --card-bg: #ffffff;
  --text: #1e293b;
  --text-light: #64748b;
  --border: #e2e8f0;
  --success: #10b981;
  --warning: #f59e0b;
  --radius: 12px;
  --radius-sm: 8px;
  --shadow-sm: 0 2px 8px rgba(0,0,0,0.04);
  --shadow-md: 0 6px 20px rgba(0,0,0,0.06);
  --shadow-lg: 0 12px 30px rgba(0,0,0,0.1);
}

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background: var(--bg);
  color: var(--text);
  line-height: 1.6;
}

/* Botones base mejorados */
button {
  font-family: inherit;
  cursor: pointer;
  transition: all 0.2s ease;
  border: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.4rem;
  font-weight: 600;
  font-size: 0.9rem;
  padding: 0.65rem 1.4rem;
  border-radius: var(--radius-sm);
  letter-spacing: 0.01em;
  box-shadow: 0 2px 6px rgba(0,0,0,0.06);
}
button:hover {
  transform: translateY(-1px);
  box-shadow: 0 6px 14px rgba(0,0,0,0.1);
}
button:active {
  transform: translateY(0);
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
}

/* Botones primarios */
.btn-primary, .add-btn, .btn-generate, .store-card-btn, .checkout-btn {
  background: linear-gradient(135deg, var(--primary), var(--primary-hover));
  color: white;
  box-shadow: 0 3px 10px rgba(13,148,136,0.3);
}
.btn-primary:hover, .add-btn:hover, .btn-generate:hover, .store-card-btn:hover, .checkout-btn:hover {
  background: linear-gradient(135deg, var(--primary-hover), var(--primary));
  box-shadow: 0 6px 16px rgba(13,148,136,0.4);
}

/* Botón de acento (naranja) */
.btn-accent, .store-card-btn.compare {
  background: linear-gradient(135deg, var(--accent), var(--accent-hover));
  color: white;
  box-shadow: 0 3px 10px rgba(249,115,22,0.35);
}
.btn-accent:hover, .store-card-btn.compare:hover {
  background: linear-gradient(135deg, var(--accent-hover), var(--accent));
  box-shadow: 0 6px 16px rgba(249,115,22,0.45);
}

/* Botones secundarios */
.btn-translate { background: #e0f2fe; color: #0369a1; border: 1px solid #bae6fd; box-shadow: none; }
.btn-translate:hover { background: #bae6fd; }
.btn-email { background: #ede9fe; color: #6b21a8; border: 1px solid #ddd6fe; box-shadow: none; }
.btn-email:hover { background: #ddd6fe; }
.btn-preview { background: #fef3c7; color: #92400e; border: 1px solid #fde68a; box-shadow: none; }
.btn-preview:hover { background: #fde68a; }
.btn-edit { background: transparent; color: var(--primary); border: 1.5px solid var(--primary); box-shadow: none; }
.btn-edit:hover { background: var(--primary); color: white; }

/* Tarjetas */
.card, .product-card, .store-card {
  background: var(--card-bg);
  border-radius: var(--radius);
  box-shadow: var(--shadow-sm);
  transition: transform 0.2s, box-shadow 0.2s;
  overflow: hidden;
}
.card:hover, .product-card:hover, .store-card:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-md);
}

/* Layout */
.app-layout { display: flex; min-height: 100vh; }
.main-area { flex: 1; display: flex; flex-direction: column; }
.content { padding: 2rem; flex: 1; }

/* Sidebar mejorada */
.sidebar {
  background: var(--sidebar-bg);
  color: var(--sidebar-text);
  padding: 1.5rem 1rem;
  border-radius: 0 var(--radius) var(--radius) 0;
  box-shadow: 2px 0 12px rgba(0,0,0,0.06);
  width: 260px;
  display: flex;
  flex-direction: column;
}
.sidebar-brand {
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--primary);
  margin-bottom: 2rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}
.sidebar-nav a {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  color: var(--sidebar-text);
  text-decoration: none;
  padding: 0.7rem 1rem;
  border-radius: var(--radius-sm);
  margin-bottom: 0.25rem;
  transition: background 0.2s;
}
.sidebar-nav a:hover,
.sidebar-nav a.active {
  background: rgba(13,148,136,0.15);
  color: var(--primary);
}

/* Header admin */
.topbar {
  background: white;
  border-bottom: 1px solid var(--border);
  padding: 0.8rem 2rem;
  border-radius: 0 0 var(--radius) var(--radius);
  box-shadow: 0 2px 8px rgba(0,0,0,0.02);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

/* Inputs con etiqueta flotante */
.input-group {
  position: relative;
  margin-bottom: 1.2rem;
}
.input-group input, .input-group select, .input-group textarea {
  width: 100%;
  padding: 0.8rem;
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  font-size: 0.95rem;
  transition: border-color 0.2s, box-shadow 0.2s;
  background: white;
}
.input-group label {
  position: absolute;
  left: 0.8rem;
  top: 0.8rem;
  pointer-events: none;
  transition: 0.2s ease all;
  color: var(--text-light);
  background: white;
  padding: 0 0.2rem;
}
.input-group input:focus ~ label,
.input-group input:not(:placeholder-shown) ~ label,
.input-group textarea:focus ~ label,
.input-group textarea:not(:placeholder-shown) ~ label {
  top: -0.6rem;
  font-size: 0.75rem;
  color: var(--primary);
}
.input-group input:focus, .input-group select:focus, .input-group textarea:focus {
  border-color: var(--primary);
  outline: none;
  box-shadow: 0 0 0 3px rgba(13,148,136,0.2);
}

/* Modal */
.modal-overlay {
  position: fixed;
  top: 0; left: 0; right: 0; bottom: 0;
  background: rgba(0,0,0,0.4);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}
.modal {
  background: white;
  border-radius: var(--radius);
  padding: 2rem;
  box-shadow: var(--shadow-lg);
  min-width: 400px;
  max-width: 500px;
}

/* Skeleton */
.skeleton-card {
  background: white;
  border-radius: var(--radius);
  overflow: hidden;
  box-shadow: var(--shadow-sm);
}
.skeleton-img {
  height: 140px;
  background: linear-gradient(90deg, #e2e8f0 25%, #f1f5f9 50%, #e2e8f0 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
}
.skeleton-body { padding: 1rem; }
.skeleton-line {
  height: 0.8rem;
  background: #e2e8f0;
  border-radius: 4px;
  margin-bottom: 0.6rem;
}
@keyframes shimmer {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}

/* Carrito */
.cart-drawer {
  position: fixed;
  top: 0; right: 0;
  width: 380px;
  height: 100vh;
  background: white;
  box-shadow: var(--shadow-lg);
  z-index: 999;
  transform: translateX(100%);
  transition: transform 0.3s ease;
  padding: 2rem 1.5rem;
  overflow-y: auto;
}
.cart-drawer.open {
  transform: translateX(0);
}
.cart-items { list-style: none; padding: 0; margin: 1rem 0; }
.cart-items li {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 0;
  border-bottom: 1px solid var(--border);
}
.cart-item-name { font-weight: 500; }
.cart-item-price { color: var(--primary); font-weight: 600; }
.cart-total { margin-top: 1.5rem; font-size: 1.2rem; }
.cart-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.3);
  z-index: 998;
}

/* Comparador */
.compare-modal { width: 90%; max-width: 900px; }
.compare-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 1.5rem;
  margin: 1.5rem 0;
}
.compare-item {
  background: #f0fdfa;
  padding: 1.5rem;
  border-radius: var(--radius-sm);
  border: 1px solid #ccfbf1;
}

/* Utilidades */
.store-container { max-width: 1280px; margin: 0 auto; padding: 2rem 1.5rem; }
.text-center { text-align: center; }
.mt-2 { margin-top: 2rem; }
EOF

# 2. AdminLayout con iconos
cat > web/src/components/AdminLayout.tsx << 'EOF'
import { Routes, Route, NavLink, useNavigate } from 'react-router-dom'
import { lazy, Suspense } from 'react'

const Dashboard = lazy(() => import('./Dashboard'))
const Products = lazy(() => import('./Products'))
const AITools = lazy(() => import('./AITools'))
const Orders = lazy(() => import('./Orders'))
const Settings = lazy(() => import('./Settings'))

export default function AdminLayout() {
  const navigate = useNavigate()

  return (
    <div className="app-layout">
      <aside className="sidebar">
        <div className="sidebar-brand">
          <span>🛍️</span> Store Manager
        </div>
        <nav className="sidebar-nav">
          <NavLink to="/admin/dashboard" className={({ isActive }) => isActive ? 'active' : ''}>
            <span>📊</span> Dashboard
          </NavLink>
          <NavLink to="/admin/products" className={({ isActive }) => isActive ? 'active' : ''}>
            <span>📦</span> Products
          </NavLink>
          <NavLink to="/admin/ai-tools" className={({ isActive }) => isActive ? 'active' : ''}>
            <span>🤖</span> AI Tools
          </NavLink>
          <NavLink to="/admin/orders" className={({ isActive }) => isActive ? 'active' : ''}>
            <span>📋</span> Orders
          </NavLink>
          <NavLink to="/admin/settings" className={({ isActive }) => isActive ? 'active' : ''}>
            <span>⚙️</span> Settings
          </NavLink>
          <button onClick={() => navigate('/')} className="store-link">
            ← Ir a la tienda
          </button>
        </nav>
      </aside>
      <div className="main-area">
        <header className="topbar">
          <h1>Panel de Administración</h1>
          <div className="user-menu">👤 Mi Tienda</div>
        </header>
        <main className="content">
          <Suspense fallback={<div>Loading...</div>}>
            <Routes>
              <Route path="dashboard" element={<Dashboard />} />
              <Route path="products" element={<Products />} />
              <Route path="ai-tools" element={<AITools />} />
              <Route path="orders" element={<Orders />} />
              <Route path="settings" element={<Settings />} />
            </Routes>
          </Suspense>
        </main>
      </div>
    </div>
  )
}
EOF

# 3. Dashboard visual
cat > web/src/components/Dashboard.tsx << 'EOF'
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
EOF

# 4. Products.tsx con formulario de etiquetas flotantes (solo la parte del form)
# Para no romper el resto del componente, reemplazamos solo la sección del formulario.
# El siguiente comando sustituye el bloque <form> existente por el nuevo.
# Ajustamos la ruta al archivo.
# Copiamos el archivo actual y luego modificamos.
cp web/src/components/Products.tsx web/src/components/Products.tsx.bak
python3 << 'PYEOF'
import re, sys

with open('web/src/components/Products.tsx', 'r') as f:
    content = f.read()

# Buscamos el formulario actual (el que empieza con <form className="add-product-form" ...)
# y lo reemplazamos por la nueva versión con input-group.
old_form = r'(<form\s+className="add-product-form"\s+onSubmit=\{handleSubmit\(data\s=>\saddMutation\.mutate\(data\)\)\}>)(.*?)(</form>)'
new_form = '''<form className="add-product-form" onSubmit={handleSubmit(data => addMutation.mutate(data))}>
          <div className="input-group">
            <input {...register('name')} placeholder=" " id="name" />
            <label htmlFor="name">Nombre del producto</label>
            {errors.name && <span className="error">{errors.name.message}</span>}
          </div>
          <div className="input-group">
            <input {...register('features')} placeholder=" " id="features" />
            <label htmlFor="features">Características clave</label>
            {errors.features && <span className="error">{errors.features.message}</span>}
          </div>
          <div className="input-group">
            <input {...register('image_url')} placeholder=" " id="image_url" />
            <label htmlFor="image_url">URL de imagen (opcional)</label>
          </div>
          <div className="input-group">
            <input type="number" step="0.01" {...register('price', { valueAsNumber: true })} placeholder=" " id="price" />
            <label htmlFor="price">Precio</label>
          </div>
          <div className="input-group">
            <select {...register('department_id', { valueAsNumber: true })} id="department">
              {departments.map((d: Department) => <option key={d.id} value={d.id}>{d.name}</option>)}
            </select>
            <label htmlFor="department">Departamento</label>
          </div>
          <button type="submit" className="btn-primary" disabled={addMutation.isPending}>
            Añadir producto
          </button>
          <small className="hint">Si no escribes descripción, la IA la generará automáticamente.</small>
        </form>'''

content = re.sub(old_form, new_form, content, flags=re.DOTALL)
with open('web/src/components/Products.tsx', 'w') as f:
    f.write(content)
print('Formulario actualizado en Products.tsx')
PYEOF

# 5. CartDrawer deslizante
cat > web/src/components/CartDrawer.tsx << 'EOF'
import { useCart } from '../context/CartContext'
import './CartDrawer.css'

export default function CartDrawer() {
  const { state, dispatch } = useCart()
  const total = state.items.reduce((sum, item) => sum + item.price, 0)
  const isEmpty = state.items.length === 0

  return (
    <>
      <div className={`cart-drawer ${isEmpty ? '' : 'open'}`}>
        <div className="cart-drawer-header">
          <h3>🛒 Carrito ({state.items.length})</h3>
          <button className="clear-cart" onClick={() => dispatch({ type: 'CLEAR' })}>Vaciar</button>
        </div>
        {isEmpty ? (
          <p className="text-center" style={{ marginTop: '2rem' }}>Tu carrito está vacío.</p>
        ) : (
          <>
            <ul className="cart-items">
              {state.items.map(item => (
                <li key={item.id}>
                  <div>
                    <span className="cart-item-name">{item.name}</span>
                    <span className="cart-item-price">${item.price.toFixed(2)}</span>
                  </div>
                  <button className="remove-item" onClick={() => dispatch({ type: 'REMOVE', id: item.id })}>×</button>
                </li>
              ))}
            </ul>
            <div className="cart-total">
              <strong>Total: ${total.toFixed(2)}</strong>
            </div>
            <button className="checkout-btn" onClick={() => alert('Compra simulada')}>
              Pagar (demo)
            </button>
          </>
        )}
      </div>
      {!isEmpty && <div className="cart-backdrop" onClick={() => dispatch({ type: 'CLEAR' })} />}
    </>
  )
}
EOF

echo "✔️ Archivos de interfaz actualizados correctamente."
