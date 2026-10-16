package metrics

import (
	"net/http"

	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// Handler returns the /metrics endpoint that Prometheus scrapes.
// It serves metrics from this Metrics instance's isolated registry.
func (m *Metrics) Handler() http.Handler {
	return promhttp.HandlerFor(m.Registry(), promhttp.HandlerOpts{
		EnableOpenMetrics: true,
	})
}
