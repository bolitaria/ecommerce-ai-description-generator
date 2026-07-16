package deepseek

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
	"github.com/sony/gobreaker"
)

type AIClient interface {
	GenerateDescription(ctx context.Context, productName, features string) (string, error)
	TranslateText(ctx context.Context, text, targetLang string) (string, error)
	GenerateEmail(ctx context.Context, productName, features string) (subject, body string, err error)
}

type client struct {
	httpClient *http.Client
	apiKey     string
	baseURL    string
	model      string
	cb         *gobreaker.CircuitBreaker
}

func NewClient(apiKey, baseURL, model string) AIClient {
	settings := gobreaker.Settings{
		Name:        "deepseek",
		MaxRequests: 3,
		Interval:    10 * time.Second,
		Timeout:     30 * time.Second,
		ReadyToTrip: func(counts gobreaker.Counts) bool {
			return counts.ConsecutiveFailures > 5
		},
	}
	return &client{
		httpClient: &http.Client{Timeout: 20 * time.Second},
		apiKey:     apiKey,
		baseURL:    baseURL,
		model:      model,
		cb:         gobreaker.NewCircuitBreaker(settings),
	}
}

type openAIRequest struct {
	Model     string          `json:"model"`
	Messages  []openAIMessage `json:"messages"`
	MaxTokens int             `json:"max_tokens"`
}
type openAIMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}
type openAIResponse struct {
	Choices []struct {
		Message struct {
			Content string `json:"content"`
		} `json:"message"`
	} `json:"choices"`
}

func (c *client) chatCompletion(ctx context.Context, prompt string, maxTokens int) (string, error) {
	reqBody := openAIRequest{
		Model: c.model,
		Messages: []openAIMessage{
			{Role: "user", Content: prompt},
		},
		MaxTokens: maxTokens,
	}
	bodyBytes, err := json.Marshal(reqBody)
	if err != nil {
		return "", err
	}
	body, err := c.cb.Execute(func() (interface{}, error) {
		req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+"/chat/completions", bytes.NewReader(bodyBytes))
		if err != nil {
			return "", err
		}
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+c.apiKey)
		resp, err := c.httpClient.Do(req)
		if err != nil {
			return "", err
		}
		defer resp.Body.Close()
		if resp.StatusCode != http.StatusOK {
			b, _ := io.ReadAll(resp.Body)
			return "", fmt.Errorf("deepseek error %d: %s", resp.StatusCode, string(b))
		}
		var aiResp openAIResponse
		if err := json.NewDecoder(resp.Body).Decode(&aiResp); err != nil {
			return "", err
		}
		if len(aiResp.Choices) == 0 {
			return "", fmt.Errorf("no choices")
		}
		return aiResp.Choices[0].Message.Content, nil
	})
	if err != nil {
		return "", err
	}
	return body.(string), nil
}

func (c *client) GenerateDescription(ctx context.Context, productName, features string) (string, error) {
	prompt := fmt.Sprintf("Write a compelling e-commerce product description for '%s'. Key features: %s. Keep under 150 words.", productName, features)
	return c.chatCompletion(ctx, prompt, 300)
}

func (c *client) TranslateText(ctx context.Context, text, targetLang string) (string, error) {
	prompt := fmt.Sprintf("Translate the following text to %s. Only return the translation:\n\n%s", targetLang, text)
	return c.chatCompletion(ctx, prompt, 300)
}

func (c *client) GenerateEmail(ctx context.Context, productName, features string) (string, string, error) {
	prompt := fmt.Sprintf(`Write a marketing email for "%s" with features: %s. Return a JSON object with "subject" (max 60 chars) and "body" (max 200 words). Only the JSON object.`, productName, features)
	raw, err := c.chatCompletion(ctx, prompt, 400)
	if err != nil {
		return "", "", err
	}
	var res struct {
		Subject string `json:"subject"`
		Body    string `json:"body"`
	}
	if err := json.Unmarshal([]byte(raw), &res); err != nil {
		return productName, raw, nil
	}
	return res.Subject, res.Body, nil
}
