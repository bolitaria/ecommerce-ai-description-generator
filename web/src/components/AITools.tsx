import { useState } from 'react'
import { useMutation } from '@tanstack/react-query'
import toast from 'react-hot-toast'

const API_URL = import.meta.env.VITE_API_URL || ''

export default function AITools() {
  // Generar descripción
  const [genName, setGenName] = useState('')
  const [genFeatures, setGenFeatures] = useState('')
  const [genResult, setGenResult] = useState('')

  const genMutation = useMutation({
    mutationFn: () =>
      fetch(`${API_URL}/api/v1/generate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ product_name: genName, features: genFeatures }),
      }).then(res => res.json()),
    onSuccess: (data) => {
      setGenResult(data.description)
      toast.success('Description generated')
    },
    onError: () => toast.error('Generation failed'),
  })

  // Traducir – la mutación recibe el texto como parámetro
  const [transText, setTransText] = useState('')
  const [transLang, setTransLang] = useState('Spanish')
  const [transResult, setTransResult] = useState('')

  const transMutation = useMutation({
    mutationFn: (text: string) =>
      fetch(`${API_URL}/api/v1/translate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text, target_lang: transLang }),
      }).then(res => res.json()),
    onSuccess: (data) => {
      setTransResult(data.translated)
      toast.success('Translation completed')
    },
    onError: () => toast.error('Translation failed'),
  })

  // Pasa la descripción generada al traductor y la traduce de inmediato
  const translateGenerated = (text: string) => {
    setTransText(text)
    transMutation.mutate(text) // aquí usamos directamente el texto
  }

  // Email
  const [emailName, setEmailName] = useState('')
  const [emailFeatures, setEmailFeatures] = useState('')
  const [emailResult, setEmailResult] = useState<{ subject: string; body: string } | null>(null)

  const emailMutation = useMutation({
    mutationFn: () =>
      fetch(`${API_URL}/api/v1/email`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ product_name: emailName, features: emailFeatures }),
      }).then(res => res.json()),
    onSuccess: (data) => {
      setEmailResult(data)
      toast.success('Email generated')
    },
    onError: () => toast.error('Email generation failed'),
  })

  return (
    <div style={{ display: 'grid', gap: '2rem' }}>
      {/* Generador de descripciones */}
      <div style={{ background: 'white', borderRadius: '12px', padding: '2rem', boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
        <h3 style={{ color: 'var(--primary)' }}>Generate Product Description</h3>
        <div style={{ display: 'flex', gap: '0.5rem', marginTop: '1rem', flexWrap: 'wrap' }}>
          <input
            placeholder="Product name"
            value={genName}
            onChange={e => setGenName(e.target.value)}
            style={{ flex: 1, padding: '0.5rem', borderRadius: '6px', border: '1px solid var(--border)' }}
          />
          <input
            placeholder="Key features"
            value={genFeatures}
            onChange={e => setGenFeatures(e.target.value)}
            style={{ flex: 1, padding: '0.5rem', borderRadius: '6px', border: '1px solid var(--border)' }}
          />
          <button
            onClick={() => genMutation.mutate()}
            disabled={!genName || !genFeatures}
            style={{ background: 'var(--primary)', color: 'white', border: 'none', padding: '0.5rem 1.5rem', borderRadius: '6px', cursor: 'pointer' }}
          >
            Generate
          </button>
        </div>
        {genResult && (
          <div style={{ marginTop: '1rem', padding: '1rem', background: '#f0fdfa', borderRadius: '8px', borderLeft: '4px solid var(--primary)' }}>
            <p>{genResult}</p>
            <button
              onClick={() => translateGenerated(genResult)}
              style={{ marginTop: '0.5rem', background: '#6366f1', color: 'white', border: 'none', padding: '0.3rem 1rem', borderRadius: '6px', cursor: 'pointer' }}
            >
              Translate this
            </button>
          </div>
        )}
      </div>

      {/* Traductor */}
      <div style={{ background: 'white', borderRadius: '12px', padding: '2rem', boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
        <h3 style={{ color: 'var(--primary)' }}>Translate Text</h3>
        <div style={{ display: 'flex', gap: '0.5rem', marginTop: '1rem', flexWrap: 'wrap' }}>
          <textarea
            placeholder="Text to translate"
            value={transText}
            onChange={e => setTransText(e.target.value)}
            rows={3}
            style={{ flex: 2, padding: '0.5rem', borderRadius: '6px', border: '1px solid var(--border)' }}
          />
          <select value={transLang} onChange={e => setTransLang(e.target.value)} style={{ padding: '0.5rem', borderRadius: '6px', border: '1px solid var(--border)' }}>
            <option>Spanish</option>
            <option>French</option>
            <option>German</option>
            <option>Italian</option>
            <option>Portuguese</option>
          </select>
          <button
            onClick={() => transMutation.mutate(transText)}
            disabled={!transText}
            style={{ background: '#6366f1', color: 'white', border: 'none', padding: '0.5rem 1.5rem', borderRadius: '6px', cursor: 'pointer' }}
          >
            Translate
          </button>
        </div>
        {transResult && (
          <div style={{ marginTop: '1rem', padding: '1rem', background: '#eef2ff', borderRadius: '8px', borderLeft: '4px solid #6366f1' }}>
            {transResult}
          </div>
        )}
      </div>

      {/* Email */}
      <div style={{ background: 'white', borderRadius: '12px', padding: '2rem', boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
        <h3 style={{ color: 'var(--primary)' }}>Generate Marketing Email</h3>
        <div style={{ display: 'flex', gap: '0.5rem', marginTop: '1rem', flexWrap: 'wrap' }}>
          <input
            placeholder="Product name"
            value={emailName}
            onChange={e => setEmailName(e.target.value)}
            style={{ flex: 1, padding: '0.5rem', borderRadius: '6px', border: '1px solid var(--border)' }}
          />
          <input
            placeholder="Key features"
            value={emailFeatures}
            onChange={e => setEmailFeatures(e.target.value)}
            style={{ flex: 1, padding: '0.5rem', borderRadius: '6px', border: '1px solid var(--border)' }}
          />
          <button
            onClick={() => emailMutation.mutate()}
            disabled={!emailName || !emailFeatures}
            style={{ background: '#475569', color: 'white', border: 'none', padding: '0.5rem 1.5rem', borderRadius: '6px', cursor: 'pointer' }}
          >
            Generate Email
          </button>
        </div>
        {emailResult && (
          <div style={{ marginTop: '1rem', padding: '1rem', background: '#f1f5f9', borderRadius: '8px' }}>
            <p><strong>Subject:</strong> {emailResult.subject}</p>
            <p><strong>Body:</strong> {emailResult.body}</p>
          </div>
        )}
      </div>
    </div>
  )
}
