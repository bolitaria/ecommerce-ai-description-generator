const Settings = () => (
  <div style={{background:'white', padding:'2rem', borderRadius:'12px', boxShadow:'0 2px 8px rgba(0,0,0,0.06)'}}>
    <h2 style={{color:'var(--primary)'}}>Store Settings</h2>
    <p style={{marginTop:'1rem'}}>Configure your store preferences, payment methods, and shipping options.</p>
    <div style={{marginTop:'2rem'}}>
      <div style={{background:'#f9f9f9', padding:'1rem', borderRadius:'8px', marginBottom:'1rem'}}>
        <strong>Store Name:</strong> My Awesome Store
      </div>
      <div style={{background:'#f9f9f9', padding:'1rem', borderRadius:'8px', marginBottom:'1rem'}}>
        <strong>Currency:</strong> USD
      </div>
      <div style={{background:'#f9f9f9', padding:'1rem', borderRadius:'8px'}}>
        <strong>Shipping Zones:</strong> North America, Europe
      </div>
    </div>
  </div>
);
export default Settings;
