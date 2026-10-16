// Package client provides HTTP clients for inter-service communication.
package client

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"time"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/domain"
	"github.com/bolitaria/ecommerce-ai-description-generator/internal/tracing"
)

const (
	headerInternalToken = "X-Internal-Token"
	headerTraceID       = "X-Trace-ID"

	defaultTimeout = 30 * time.Second
	maxRetries     = 2
	initialBackoff = 100 * time.Millisecond
	backoffFactor  = 3
)

// AIClient is the HTTP client for the AI Service.
// It implements domain.AIGenerator, so it can be injected as a drop-in
// replacement for the local FallbackGenerator.
type AIClient struct {
	baseURL string
	token   string
	http    *http.Client
	logger  *slog.Logger
}

// New builds an AIClient. If token is empty, internal auth is skipped
// (dev mode). If logger is nil, slog.Default() is used.
func New(baseURL, token string, logger *slog.Logger) *AIClient {
	if logger == nil {
		logger = slog.Default()
	}
	return &AIClient{
		baseURL: baseURL,
		token:   token,
		http:    &http.Client{Timeout: defaultTimeout},
		logger:  logger,
	}
}

// Compile-time assertion: AIClient satisfies domain.AIGenerator.
var _ domain.AIGenerator = (*AIClient)(nil)

// GenerateDescription calls POST /v1/descriptions.
func (c *AIClient) GenerateDescription(ctx context.Context, productName, features string) (string, error) {
	var resp struct {
		Description string `json:"description"`
	}
	if err := c.post(ctx, "/v1/descriptions", map[string]string{
		"product_name": productName,
		"features":     features,
	}, &resp); err != nil {
		return "", err
	}
	return resp.Description, nil
}

// TranslateText calls POST /v1/translations.
func (c *AIClient) TranslateText(ctx context.Context, text, targetLang string) (string, error) {
	var resp struct {
		Translated string `json:"translated"`
	}
	if err := c.post(ctx, "/v1/translations", map[string]string{
		"text":        text,
		"target_lang": targetLang,
	}, &resp); err != nil {
		return "", err
	}
	return resp.Translated, nil
}

// GenerateEmail calls POST /v1/emails.
func (c *AIClient) GenerateEmail(ctx context.Context, productName, features string) (string, string, error) {
	var resp struct {
		Subject string `json:"subject"`
		Body    string `json:"body"`
	}
	if err := c.post(ctx, "/v1/emails", map[string]string{
		"product_name": productName,
		"features":     features,
	}, &resp); err != nil {
		return "", "", err
	}
	return resp.Subject, resp.Body, nil
}

// HealthCheck pings the AI Service's /healthz endpoint.
func (c *AIClient) HealthCheck(ctx context.Context) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.baseURL+"/healthz", nil)
	if err != nil {
		return err
	}
	resp, err := c.http.Do(req)
	if err != nil {
		return err
	}
	defer func() { _ = resp.Body.Close() }()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("healthcheck returned %d", resp.StatusCode)
	}
	return nil
}

// post marshals body, performs the request with retries, and decodes out.
func (c *AIClient) post(ctx context.Context, path string, body, out any) error {
	bodyBytes, err := json.Marshal(body)
	if err != nil {
		return fmt.Errorf("marshal body: %w", err)
	}

	var lastErr error
	backoff := initialBackoff

	for attempt := 0; attempt <= maxRetries; attempt++ {
		if attempt > 0 {
			select {
			case <-ctx.Done():
				return ctx.Err()
			case <-time.After(backoff):
			}
			backoff *= backoffFactor
		}

		err := c.do(ctx, path, bodyBytes, out)
		if err == nil {
			return nil
		}

		// Do not retry client errors (4xx), except 429 Too Many Requests.
		var httpErr *httpError
		if errors.As(err, &httpErr) &&
			httpErr.Status >= 400 && httpErr.Status < 500 &&
			httpErr.Status != http.StatusTooManyRequests {
			return err
		}

		lastErr = err
		c.logger.Warn("ai-service call failed",
			"path", path,
			"attempt", attempt+1,
			"error", err,
		)
	}
	return fmt.Errorf("all attempts failed: %w", lastErr)
}

// do performs a single HTTP POST.
func (c *AIClient) do(ctx context.Context, path string, body []byte, out any) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+path, bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	if c.token != "" {
		req.Header.Set(headerInternalToken, c.token)
	}
	if traceID := tracing.TraceIDFromContext(ctx); traceID != "" {
		req.Header.Set(headerTraceID, traceID)
	}

	resp, err := c.http.Do(req)
	if err != nil {
		return err
	}
	defer func() { _ = resp.Body.Close() }()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		b, _ := io.ReadAll(resp.Body)
		return &httpError{Status: resp.StatusCode, Body: string(b)}
	}
	if err := json.NewDecoder(resp.Body).Decode(out); err != nil {
		return fmt.Errorf("decode response: %w", err)
	}
	return nil
}

type httpError struct {
	Status int
	Body   string
}

func (e *httpError) Error() string {
	return fmt.Sprintf("ai-service returned %d: %s", e.Status, e.Body)
}
