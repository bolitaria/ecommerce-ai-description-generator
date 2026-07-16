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
