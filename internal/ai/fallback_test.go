package ai

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"testing"

	"github.com/bolitaria/ecommerce-ai-description-generator/internal/domain"
)

// stubProvider is a test double implementing domain.AIGenerator.
type stubProvider struct {
	name  string
	err   error
	reply string
	calls int
}

func (s *stubProvider) GenerateDescription(ctx context.Context, productName, features string) (string, error) {
	s.calls++
	if s.err != nil {
		return "", s.err
	}
	return s.reply, nil
}

func (s *stubProvider) TranslateText(ctx context.Context, text, targetLang string) (string, error) {
	s.calls++
	if s.err != nil {
		return "", s.err
	}
	return s.reply, nil
}

func (s *stubProvider) GenerateEmail(ctx context.Context, productName, features string) (string, string, error) {
	s.calls++
	if s.err != nil {
		return "", "", s.err
	}
	return "subject", s.reply, nil
}

func newTestGenerator(t *testing.T, providers ...namedProvider) *FallbackGenerator {
	t.Helper()
	logger := slog.New(slog.NewTextHandler(io.Discard, nil))
	return NewFallbackGenerator(providers, logger)
}

func TestFallback_UsesFirstProviderWhenHealthy(t *testing.T) {
	ok := &stubProvider{name: "ok", reply: "hello"}
	other := &stubProvider{name: "other", reply: "nope"}
	g := newTestGenerator(t,
		namedProvider{name: "ok", client: ok},
		namedProvider{name: "other", client: other},
	)

	got, err := g.GenerateDescription(context.Background(), "p", "f")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != "hello" {
		t.Fatalf("expected hello, got %q", got)
	}
	if ok.calls != 1 || other.calls != 0 {
		t.Fatalf("expected only first provider called, got ok=%d other=%d", ok.calls, other.calls)
	}
}

func TestFallback_FallsOverOnError(t *testing.T) {
	broken := &stubProvider{name: "broken", err: errors.New("boom")}
	ok := &stubProvider{name: "ok", reply: "rescued"}
	g := newTestGenerator(t,
		namedProvider{name: "broken", client: broken},
		namedProvider{name: "ok", client: ok},
	)

	got, err := g.GenerateDescription(context.Background(), "p", "f")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != "rescued" {
		t.Fatalf("expected rescued, got %q", got)
	}
	if broken.calls != 1 || ok.calls != 1 {
		t.Fatalf("expected both called, got broken=%d ok=%d", broken.calls, ok.calls)
	}
}

func TestFallback_AllFailReturnsError(t *testing.T) {
	a := &stubProvider{name: "a", err: errors.New("a-down")}
	b := &stubProvider{name: "b", err: errors.New("b-down")}
	g := newTestGenerator(t,
		namedProvider{name: "a", client: a},
		namedProvider{name: "b", client: b},
	)

	_, err := g.GenerateDescription(context.Background(), "p", "f")
	if err == nil {
		t.Fatal("expected error, got nil")
	}
	if a.calls != 1 || b.calls != 1 {
		t.Fatalf("expected both called, got a=%d b=%d", a.calls, b.calls)
	}
}

func TestFallback_TranslateAndEmail(t *testing.T) {
	ok := &stubProvider{name: "ok", reply: "translated"}
	g := newTestGenerator(t, namedProvider{name: "ok", client: ok})

	if _, err := g.TranslateText(context.Background(), "hola", "en"); err != nil {
		t.Fatalf("translate failed: %v", err)
	}
	if _, _, err := g.GenerateEmail(context.Background(), "p", "f"); err != nil {
		t.Fatalf("email failed: %v", err)
	}
	if ok.calls != 2 {
		t.Fatalf("expected 2 calls, got %d", ok.calls)
	}
}

// Compile-time assertion.
var _ domain.AIGenerator = (*FallbackGenerator)(nil)
