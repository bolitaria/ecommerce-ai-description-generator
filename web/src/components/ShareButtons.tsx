interface ShareProps {
  product: {
    name: string
    description?: string
    price: number
  }
}

export default function ShareButtons({ product }: ShareProps) {
  const text = `${product.name} – $${product.price.toFixed(2)}: ${product.description?.slice(0, 80)}...`

  const handleShare = async () => {
    if (navigator.share) {
      try {
        await navigator.share({ title: product.name, text })
      } catch {}
    } else {
      window.open(`https://wa.me/?text=${encodeURIComponent(text)}`, '_blank')
    }
  }

  return (
    <button onClick={handleShare} className="share-btn" title="Compartir">
      📤
    </button>
  )
}