// Package tracing provides a minimal trace ID propagation mechanism across
// HTTP boundaries. The Core API generates a trace ID per incoming request
// and forwards it to the AI Service via the X-Trace-ID header.
package tracing

import "context"

type contextKey struct{}

// WithTraceID returns a new context with the trace ID attached.
func WithTraceID(ctx context.Context, traceID string) context.Context {
	return context.WithValue(ctx, contextKey{}, traceID)
}

// TraceIDFromContext extracts the trace ID from the context, or "" if absent.
func TraceIDFromContext(ctx context.Context) string {
	if id, ok := ctx.Value(contextKey{}).(string); ok {
		return id
	}
	return ""
}
