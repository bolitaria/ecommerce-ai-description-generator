import { createContext, useContext, useState, useCallback } from 'react'
import type { ReactNode } from 'react'

interface CompareContextType {
  compareItems: number[]
  toggleCompare: (id: number) => void
  clearCompare: () => void
}

const CompareContext = createContext<CompareContextType | null>(null)

export function CompareProvider({ children }: { children: ReactNode }) {
  const [compareItems, setCompareItems] = useState<number[]>([])

  const toggleCompare = useCallback(
    (id: number) => setCompareItems(prev => prev.includes(id) ? prev.filter(i => i !== id) : prev.length < 3 ? [...prev, id] : prev),
    []
  )
  const clearCompare = () => setCompareItems([])

  return (
    <CompareContext.Provider value={{ compareItems, toggleCompare, clearCompare }}>
      {children}
    </CompareContext.Provider>
  )
}

export function useCompare() {
  const ctx = useContext(CompareContext)
  if (!ctx) throw new Error('useCompare debe usarse dentro de CompareProvider')
  return ctx
}