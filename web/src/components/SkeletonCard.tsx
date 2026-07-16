import './SkeletonCard.css'

export default function SkeletonCard() {
  return (
    <div className="skeleton-card">
      <div className="skeleton-img" />
      <div className="skeleton-body">
        <div className="skeleton-line" style={{ width: '80%' }} />
        <div className="skeleton-line" style={{ width: '60%' }} />
        <div className="skeleton-line" style={{ width: '40%' }} />
      </div>
    </div>
  )
}