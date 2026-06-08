import { useState, useEffect } from 'react';
import './Products.css';

const API_URL = import.meta.env.VITE_API_URL || '';

interface Product {
  id: number;
  name: string;
  features: string;
  description: string;
  department_id: number;
  department_name: string;
}

interface Department {
  id: number;
  name: string;
}

export default function Products() {
  const [products, setProducts] = useState<Product[]>([]);
  const [departments, setDepartments] = useState<Department[]>([]);
  const [loadingId, setLoadingId] = useState<number | null>(null);
  const [error, setError] = useState('');
  const [newName, setNewName] = useState('');
  const [newFeatures, setNewFeatures] = useState('');
  const [newDepartment, setNewDepartment] = useState(1);
  const [filterDepartment, setFilterDepartment] = useState('');
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [translateModal, setTranslateModal] = useState<Product | null>(null);
  const [translatedText, setTranslatedText] = useState('');
  const [emailModal, setEmailModal] = useState<{ subject: string; body: string } | null>(null);

  useEffect(() => {
    fetch(`${API_URL}/api/departments`)
      .then(res => res.json())
      .then(setDepartments)
      .catch(() => {});
  }, []);

  useEffect(() => {
    const params = new URLSearchParams();
    if (filterDepartment) params.append('department_id', filterDepartment);
    if (search) params.append('search', search);
    params.append('page', String(page));
    params.append('limit', '6');  // mostramos 6 productos por página
    fetch(`${API_URL}/api/products?${params}`)
      .then(res => {
        const total = res.headers.get('X-Total-Count');
        if (total) setTotalPages(Math.ceil(Number(total) / 6));
        return res.json();
      })
      .then(data => setProducts(data))
      .catch(() => setError('Failed to load products'));
  }, [filterDepartment, search, page]);

  const addProduct = async () => {
    if (!newName.trim() || !newFeatures.trim()) {
      setError('Name and features are required.');
      return;
    }
    await fetch(`${API_URL}/api/products`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: newName, features: newFeatures, department_id: newDepartment }),
    });
    setNewName('');
    setNewFeatures('');
    setPage(1);
    // Refresca productos
    setFilterDepartment(filterDepartment); // trigger fetch
  };

  const generateDescription = async (product: Product) => {
    setLoadingId(product.id);
    setError('');
    try {
      const res = await fetch(`${API_URL}/generate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ product_name: product.name, features: product.features }),
      });
      if (!res.ok) throw new Error('Generation failed');
      const data = await res.json();
      // Update local
      setProducts(prev => prev.map(p => p.id === product.id ? { ...p, description: data.description } : p));
      // Update backend
      await fetch(`${API_URL}/api/products/${product.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...product, description: data.description }),
      });
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoadingId(null);
    }
  };

  const openTranslate = (product: Product) => {
    setTranslateModal(product);
    setTranslatedText('');
  };

  const handleTranslate = async (lang: string) => {
    if (!translateModal || !translateModal.description) return;
    setLoadingId(translateModal.id);
    try {
      const res = await fetch(`${API_URL}/translate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text: translateModal.description, target_lang: lang }),
      });
      const data = await res.json();
      setTranslatedText(data.translated);
    } catch (e) {
      console.error(e);
    } finally {
      setLoadingId(null);
    }
  };

  const openEmail = async (product: Product) => {
    setLoadingId(product.id);
    try {
      const res = await fetch(`${API_URL}/email`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ product_name: product.name, features: product.features }),
      });
      const data = await res.json();
      setEmailModal(data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoadingId(null);
    }
  };

  return (
    <div className="products-container">
      <div className="add-product-section">
        <h3>Add New Product</h3>
        <div className="add-product-form">
          <input type="text" placeholder="Product name" value={newName} onChange={e => setNewName(e.target.value)} />
          <input type="text" placeholder="Key features" value={newFeatures} onChange={e => setNewFeatures(e.target.value)} />
          <select value={newDepartment} onChange={e => setNewDepartment(Number(e.target.value))}>
            {departments.map(d => <option key={d.id} value={d.id}>{d.name}</option>)}
          </select>
          <button onClick={addProduct} className="add-btn">Add Product</button>
        </div>
      </div>

      <div className="filters">
        <select value={filterDepartment} onChange={e => setFilterDepartment(e.target.value)}>
          <option value="">All Departments</option>
          {departments.map(d => <option key={d.id} value={d.id}>{d.name}</option>)}
        </select>
        <input type="text" placeholder="Search products..." value={search} onChange={e => setSearch(e.target.value)} />
      </div>

      {error && <div className="error-banner">{error}</div>}

      <div className="product-grid">
        {products.map(product => (
          <div key={product.id} className="product-card">
            <div className="product-img-placeholder">
              <span>{product.department_name}</span>
            </div>
            <div className="product-info">
              <h4>{product.name}</h4>
              <p className="features">{product.features}</p>
              <p className="description">
                {product.description ? product.description : <i>No description yet</i>}
              </p>
              <div className="card-actions">
                <button className="btn-generate" onClick={() => generateDescription(product)} disabled={loadingId === product.id}>
                  {loadingId === product.id ? '...' : 'Generate'}
                </button>
                <button className="btn-translate" onClick={() => openTranslate(product)} disabled={!product.description}>
                  Translate
                </button>
                <button className="btn-email" onClick={() => openEmail(product)}>
                  Email
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {products.length === 0 && <div className="empty">No products found.</div>}

      <div className="pagination">
        <button disabled={page <= 1} onClick={() => setPage(p => p - 1)}>Previous</button>
        <span>Page {page} of {totalPages}</span>
        <button disabled={page >= totalPages} onClick={() => setPage(p => p + 1)}>Next</button>
      </div>

      {/* Translate Modal */}
      {translateModal && (
        <div className="modal-overlay" onClick={() => setTranslateModal(null)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <h3>Translate Description</h3>
            <p><strong>{translateModal.name}:</strong> {translateModal.description}</p>
            <select defaultValue="" onChange={e => handleTranslate(e.target.value)}>
              <option value="" disabled>Select language</option>
              <option value="Spanish">Spanish</option>
              <option value="French">French</option>
              <option value="German">German</option>
            </select>
            {translatedText && <div className="result-box">{translatedText}</div>}
            <button onClick={() => setTranslateModal(null)}>Close</button>
          </div>
        </div>
      )}

      {/* Email Modal */}
      {emailModal && (
        <div className="modal-overlay" onClick={() => setEmailModal(null)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <h3>Marketing Email</h3>
            <p><strong>Subject:</strong> {emailModal.subject}</p>
            <p><strong>Body:</strong> {emailModal.body}</p>
            <button onClick={() => setEmailModal(null)}>Close</button>
          </div>
        </div>
      )}
    </div>
  );
}