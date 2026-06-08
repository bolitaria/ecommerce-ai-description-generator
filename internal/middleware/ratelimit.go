package middleware

import (
	"net/http"
	"sync"

	"golang.org/x/time/rate"
)

// RateLimitPerIP returns a middleware that limits the number of requests per second per IP.
func RateLimitPerIP(rps float64) func(http.Handler) http.Handler {
	var mu sync.Mutex
	visitors := make(map[string]*rate.Limiter)

	getLimiter := func(ip string) *rate.Limiter {
		mu.Lock()
		defer mu.Unlock()
		limiter, exists := visitors[ip]
		if !exists {
			limiter = rate.NewLimiter(rate.Limit(rps), int(rps*2))
			visitors[ip] = limiter
		}
		return limiter
	}

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ip := r.RemoteAddr
			limiter := getLimiter(ip)
			if !limiter.Allow() {
				http.Error(w, "Rate limit exceeded", http.StatusTooManyRequests)
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}