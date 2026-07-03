import React, { useState, lazy, Suspense } from 'react'
import './App.css'

const Dashboard = lazy(() => import('./components/Dashboard'))
const Products = lazy(() => import('./components/Products'))
const AITools = lazy(() => import('./components/AITools'))
const Orders = lazy(() => import('./components/Orders'))
const Settings = lazy(() => import('./components/Settings'))

function App() {
  const [activeView, setActiveView] = useState('dashboard')

  const renderView = () => {
    const views: Record<string, React.JSX.Element> = {
      dashboard: <Dashboard />,
      products: <Products />,
      'ai-tools': <AITools />,
      orders: <Orders />,
      settings: <Settings />,
    }
    return views[activeView] || <Dashboard />
  }

  return (
    <div className="app-layout">
      <aside className="sidebar">
        <div className="sidebar-brand">Store Manager</div>
        <nav className="sidebar-nav">
          {['dashboard', 'products', 'ai-tools', 'orders', 'settings'].map(v => (
            <a key={v} href="#" className={activeView === v ? 'active' : ''} onClick={() => setActiveView(v)}>
              {v.charAt(0).toUpperCase() + v.slice(1).replace('-', ' ')}
            </a>
          ))}
        </nav>
      </aside>
      <div className="main-area">
        <header className="topbar">
          <h1>{activeView.charAt(0).toUpperCase() + activeView.slice(1)}</h1>
          <div className="user-menu">My Store</div>
        </header>
        <main className="content">
          <Suspense fallback={<div>Loading...</div>}>
            {renderView()}
          </Suspense>
        </main>
      </div>
    </div>
  )
}

export default App
