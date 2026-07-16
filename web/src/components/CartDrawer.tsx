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
