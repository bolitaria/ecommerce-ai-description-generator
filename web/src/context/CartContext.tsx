import { createContext, useContext, useReducer } from 'react'
import type { ReactNode } from 'react'

export interface CartItem {
  id: number
  name: string
  price: number
  image_url?: string
}

interface CartState {
  items: CartItem[]
}

type CartAction =
  | { type: 'ADD'; item: CartItem }
  | { type: 'REMOVE'; id: number }
  | { type: 'CLEAR' }

const CartContext = createContext<{
  state: CartState
  dispatch: React.Dispatch<CartAction>
} | null>(null)

function cartReducer(state: CartState, action: CartAction): CartState {
  switch (action.type) {
    case 'ADD':
      if (state.items.find(i => i.id === action.item.id)) return state
      return { ...state, items: [...state.items, action.item] }
    case 'REMOVE':
      return { ...state, items: state.items.filter(i => i.id !== action.id) }
    case 'CLEAR':
      return { items: [] }
    default:
      return state
  }
}

export function CartProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(cartReducer, { items: [] })
  return <CartContext.Provider value={{ state, dispatch }}>{children}</CartContext.Provider>
}

export function useCart() {
  const ctx = useContext(CartContext)
  if (!ctx) throw new Error('useCart debe usarse dentro de CartProvider')
  return ctx
}