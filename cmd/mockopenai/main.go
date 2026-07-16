package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"regexp"
	"strings"
)

type mockResponse struct {
	Choices []struct {
		Message struct {
			Content string `json:"content"`
		} `json:"message"`
	} `json:"choices"`
}

func main() {
	http.HandleFunc("/v1/chat/completions", func(w http.ResponseWriter, r *http.Request) {
		bodyBytes, _ := io.ReadAll(r.Body)
		var req map[string]interface{}
		json.Unmarshal(bodyBytes, &req)

		messages := req["messages"].([]interface{})
		userMsg := messages[0].(map[string]interface{})["content"].(string)

		var content string
		switch {
		case strings.Contains(userMsg, "Translate the following text"):
			content = mockTranslate(userMsg)
		case strings.Contains(userMsg, "marketing email"):
			content = mockEmail(userMsg)
		default:
			content = mockDescription(userMsg)
		}

		resp := mockResponse{
			Choices: []struct {
				Message struct {
					Content string `json:"content"`
				} `json:"message"`
			}{
				{Message: struct {
					Content string `json:"content"`
				}{Content: content}},
			},
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(resp)
	})
	log.Println("Mock DeepSeek listening on :5000")
	http.ListenAndServe(":5000", nil)
}

func mockTranslate(prompt string) string {
	lang := "Spanish"
	text := ""
	if idx := strings.Index(prompt, "Translate the following text to "); idx != -1 {
		start := idx + len("Translate the following text to ")
		end := strings.Index(prompt[start:], ".")
		if end != -1 {
			lang = prompt[start : start+end]
		}
	}
	parts := strings.Split(prompt, "\n\n")
	if len(parts) > 1 {
		text = strings.TrimSpace(parts[len(parts)-1])
	}
	if text == "" {
		text = "(no text)"
	}
	switch lang {
	case "Spanish":
		return "[ES] " + text + " (traducción simulada)"
	case "French":
		return "[FR] " + text + " (traduction simulée)"
	case "German":
		return "[DE] " + text + " (simulierte Übersetzung)"
	case "English":
		return "[EN] " + text + " (simulated translation)"
	default:
		return fmt.Sprintf("[%s] %s", lang, text)
	}
}

func mockEmail(prompt string) string {
	name, feat := extractInfo(prompt)
	return fmt.Sprintf(`{"subject":"Novedad: %s ya disponible","body":"Hola,\n\nTe presentamos nuestro nuevo producto: %s.\n\n%s\n\n¡Pídelo ahora con un 10%% de descuento!\n\nSaludos,\nTu tienda de confianza"}`, name, name, feat)
}

func mockDescription(prompt string) string {
	name, feat := extractInfo(prompt)
	templates := []string{
		fmt.Sprintf("%s es la elección perfecta. %s. Fabricado con materiales de primera calidad y un diseño pensado para durar.", name, feat),
		fmt.Sprintf("Descubre %s. %s. Una combinación ideal de funcionalidad y estilo, adecuado para cualquier ocasión.", name, feat),
		fmt.Sprintf("%s marca la diferencia. %s. Innovación y confort en un solo producto. Supera tus expectativas.", name, feat),
	}
	return templates[len(name)%len(templates)]
}

func extractInfo(prompt string) (string, string) {
	name := "Producto"
	features := "características excepcionales"
	re := regexp.MustCompile(`for '([^']+)'`)
	if matches := re.FindStringSubmatch(prompt); len(matches) > 1 {
		name = matches[1]
	}
	if idx := strings.Index(prompt, "Key features:"); idx != -1 {
		start := idx + len("Key features:")
		featuresPart := strings.TrimSpace(prompt[start:])
		if end := strings.Index(featuresPart, "."); end != -1 {
			features = strings.TrimSpace(featuresPart[:end])
		} else {
			features = featuresPart
		}
	}
	return name, features
}
