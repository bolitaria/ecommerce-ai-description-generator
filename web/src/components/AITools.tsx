const AITools = () => (
  <div style={{background:'white', padding:'2rem', borderRadius:'12px', boxShadow:'0 2px 8px rgba(0,0,0,0.06)'}}>
    <h2 style={{color:'var(--primary)'}}>AI Content Tools</h2>
    <p style={{marginTop:'1rem'}}>Generate product descriptions, translations, and marketing copy with a single click.</p>
    <div style={{marginTop:'2rem', display:'grid', gridTemplateColumns:'repeat(auto-fill, minmax(200px,1fr))', gap:'1rem'}}>
      <div style={{background:'#f9f9f9', padding:'1.5rem', borderRadius:'8px', textAlign:'center'}}>
        <h3>Description Generator</h3>
        <p>Create SEO-friendly product descriptions.</p>
      </div>
      <div style={{background:'#f9f9f9', padding:'1.5rem', borderRadius:'8px', textAlign:'center'}}>
        <h3>Translation</h3>
        <p>Translate store content into multiple languages.</p>
      </div>
      <div style={{background:'#f9f9f9', padding:'1.5rem', borderRadius:'8px', textAlign:'center'}}>
        <h3>Ad Copy</h3>
        <p>Generate catchy ad headlines and copy.</p>
      </div>
    </div>
  </div>
);
export default AITools;
