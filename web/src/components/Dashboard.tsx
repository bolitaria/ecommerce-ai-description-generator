const Dashboard = () => (
  <div style={{background:'white', padding:'2rem', borderRadius:'12px', boxShadow:'0 2px 8px rgba(0,0,0,0.06)'}}>
    <h2 style={{color:'var(--primary)'}}>Welcome back, Seller!</h2>
    <div style={{display:'flex', gap:'2rem', marginTop:'1.5rem'}}>
      <div style={{background:'#f9f9f9', padding:'1.5rem', borderRadius:'8px', flex:1}}>
        <h3>Products</h3>
        <p style={{fontSize:'2rem', fontWeight:'bold'}}>24</p>
      </div>
      <div style={{background:'#f9f9f9', padding:'1.5rem', borderRadius:'8px', flex:1}}>
        <h3>Orders</h3>
        <p style={{fontSize:'2rem', fontWeight:'bold'}}>142</p>
      </div>
      <div style={{background:'#f9f9f9', padding:'1.5rem', borderRadius:'8px', flex:1}}>
        <h3>Revenue</h3>
        <p style={{fontSize:'2rem', fontWeight:'bold'}}>$4,280</p>
      </div>
    </div>
  </div>
);
export default Dashboard;
