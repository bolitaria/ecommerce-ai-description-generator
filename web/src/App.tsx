import { useState } from 'react';
import './App.css';
import Dashboard from './components/Dashboard';
import Products from './components/Products';
import AITools from './components/AITools';
import Orders from './components/Orders';
import Settings from './components/Settings';

function App() {
  const [activeView, setActiveView] = useState('dashboard');

  const renderView = () => {
    switch (activeView) {
      case 'dashboard': return <Dashboard />;
      case 'products': return <Products />;
      case 'ai-tools': return <AITools />;
      case 'orders': return <Orders />;
      case 'settings': return <Settings />;
      default: return <Dashboard />;
    }
  };

  return (
    <div className="app-layout">
      <aside className="sidebar">
        <div className="sidebar-brand">Store Manager</div>
        <nav className="sidebar-nav">
          <a href="#" className={activeView === 'dashboard' ? 'active' : ''} onClick={() => setActiveView('dashboard')}>Dashboard</a>
          <a href="#" className={activeView === 'products' ? 'active' : ''} onClick={() => setActiveView('products')}>Products</a>
          <a href="#" className={activeView === 'ai-tools' ? 'active' : ''} onClick={() => setActiveView('ai-tools')}>AI Tools</a>
          <a href="#" className={activeView === 'orders' ? 'active' : ''} onClick={() => setActiveView('orders')}>Orders</a>
          <a href="#" className={activeView === 'settings' ? 'active' : ''} onClick={() => setActiveView('settings')}>Settings</a>
        </nav>
      </aside>
      <div className="main-area">
        <header className="topbar">
          <h1>{activeView.charAt(0).toUpperCase() + activeView.slice(1)}</h1>
          <div className="user-menu">My Store</div>
        </header>
        <main className="content">
          {renderView()}
        </main>
      </div>
    </div>
  );
}

export default App;