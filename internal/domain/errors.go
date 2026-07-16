package domain

type ValidationError struct {
	message string
}

func (e *ValidationError) Error() string { return e.message }
func ErrValidation(msg string) error     { return &ValidationError{message: msg} }