package domain
import "context"
type AIGenerator interface {
	GenerateDescription(ctx context.Context, productName, features string) (string, error)
	TranslateText(ctx context.Context, text, targetLang string) (string, error)
	GenerateEmail(ctx context.Context, productName, features string) (subject, body string, err error)
}
