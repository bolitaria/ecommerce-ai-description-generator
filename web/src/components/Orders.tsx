const Orders = () => (
  <div style={{background:'white', padding:'2rem', borderRadius:'12px', boxShadow:'0 2px 8px rgba(0,0,0,0.06)'}}>
    <h2 style={{color:'var(--primary)'}}>Recent Orders</h2>
    <table style={{width:'100%', marginTop:'1rem', borderCollapse:'collapse'}}>
      <thead>
        <tr><th style={{textAlign:'left', padding:'0.5rem'}}>Order ID</th><th style={{textAlign:'left', padding:'0.5rem'}}>Product</th><th style={{textAlign:'left', padding:'0.5rem'}}>Status</th></tr>
      </thead>
      <tbody>
        <tr><td style={{padding:'0.5rem'}}>#1001</td><td style={{padding:'0.5rem'}}>Sticker Pack</td><td style={{padding:'0.5rem', color:'green'}}>Shipped</td></tr>
        <tr><td style={{padding:'0.5rem'}}>#1002</td><td style={{padding:'0.5rem'}}>Custom T-Shirt</td><td style={{padding:'0.5rem', color:'orange'}}>Processing</td></tr>
        <tr><td style={{padding:'0.5rem'}}>#1003</td><td style={{padding:'0.5rem'}}>Mug 11oz</td><td style={{padding:'0.5rem', color:'blue'}}>Pending</td></tr>
      </tbody>
    </table>
  </div>
);
export default Orders;
