package openai

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
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
}

func NewClient(apiKey, baseURL, model string) AIClient {
	return &client{
		httpClient: &http.Client{Timeout: 20 * time.Second},
		apiKey:     apiKey,
		baseURL:    baseURL,
		model:      model,
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

func (c *client) GenerateDescription(ctx context.Context, productName, features string) (string, error) {
	prompt := fmt.Sprintf(
		"Write a compelling e-commerce product description for '%s'. Key features: %s. Keep under 150 words, professional yet friendly.",
		productName, features)
	return c.chatCompletion(ctx, prompt, 300)
}

func (c *client) TranslateText(ctx context.Context, text, targetLang string) (string, error) {
	prompt := fmt.Sprintf("Translate the following text to %s. Only return the translation:\n\n%s", targetLang, text)
	return c.chatCompletion(ctx, prompt, 300)
}

func (c *client) GenerateEmail(ctx context.Context, productName, features string) (string, string, error) {
	prompt := fmt.Sprintf(
		`Write a marketing email for the product "%s" with features: %s.
Return a JSON object with fields "subject" (catchy subject line, max 60 chars) and "body" (friendly email body, max 200 words).
Only the JSON object, nothing else.`,
		productName, features)
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
		return "", fmt.Errorf("marshal request: %w", err)
	}
	var resp *http.Response
	for attempt := 1; attempt <= 3; attempt++ {
		req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+"/chat/completions", bytes.NewReader(bodyBytes))
		if err != nil {
			return "", fmt.Errorf("create request: %w", err)
		}
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+c.apiKey)
		resp, err = c.httpClient.Do(req)
		if err == nil && resp.StatusCode < 500 {
			break
		}
		if attempt < 3 {
			time.Sleep(time.Duration(attempt) * time.Second)
		}
	}
	if err != nil {
		return "", fmt.Errorf("openai request: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("openai returned %d: %s", resp.StatusCode, string(body))
	}
	var aiResp openAIResponse
	if err := json.NewDecoder(resp.Body).Decode(&aiResp); err != nil {
		return "", fmt.Errorf("decode response: %w", err)
	}
	if len(aiResp.Choices) == 0 {
		return "", fmt.Errorf("no choices in response")
	}
	return aiResp.Choices[0].Message.Content, nil
}
