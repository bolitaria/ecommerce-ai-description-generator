import { lazy, Suspense } from 'react'
import { BrowserRouter, Routes, Route } from 'react-router-dom'
import { CartProvider } from './context/CartContext'
import { CompareProvider } from './context/CompareContext'
import CartDrawer from './components/CartDrawer'
import CompareModal from './components/CompareModal'
import './App.css'

const Store = lazy(() => import('./components/Store'))
const ProductDetail = lazy(() => import('./components/ProductDetail'))
const AdminLayout = lazy(() => import('./components/AdminLayout'))

export default function App() {
  return (
    <CartProvider>
      <CompareProvider>
        <BrowserRouter>
          <Suspense fallback={<div className="app-loading">Cargando aplicación...</div>}>
            <Routes>
              <Route path="/" element={<Store />} />
              <Route path="/product/:id" element={<ProductDetail />} />
              <Route path="/admin/*" element={<AdminLayout />} />
            </Routes>
          </Suspense>
          <CartDrawer />
          <CompareModal />
        </BrowserRouter>
      </CompareProvider>
    </CartProvider>
  )
}