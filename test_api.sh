#!/bin/bash
BASE="http://localhost:8080/api/v1"
PASS=0
FAIL=0

check() {
  if [ "$1" -eq "$2" ]; then
    echo "✅ $3"
    PASS=$((PASS+1))
  else
    echo "❌ $3 (esperado $2, recibido $1)"
    FAIL=$((FAIL+1))
  fi
}

echo "=============================="
echo "🔍 Testeando API de productos"
echo "=============================="

# Health check (ruta directa)
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health)
check "$STATUS" 200 "Health check"

# Departamentos
RESP=$(curl -s "$BASE/departments")
DEPS=$(echo "$RESP" | jq '.departments | length')
if [ "$DEPS" -gt 0 ]; then
  echo "✅ Departamentos: $DEPS encontrados"
  PASS=$((PASS+1))
else
  echo "❌ Departamentos vacíos"
  FAIL=$((FAIL+1))
fi

# Crear producto
CREATE=$(curl -s -X POST "$BASE/products" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test AI","features":"prueba","price":19.99,"department_id":1}')
PROD_ID=$(echo "$CREATE" | jq -r '.id')
if [ "$PROD_ID" != "null" ] && [ -n "$PROD_ID" ]; then
  echo "✅ Producto creado con ID $PROD_ID"
  PASS=$((PASS+1))
else
  echo "❌ Fallo al crear producto"
  FAIL=$((FAIL+1))
fi

# Obtener producto por ID
if [ -n "$PROD_ID" ]; then
  GET_RESP=$(curl -s "$BASE/products/$PROD_ID")
  GET_NAME=$(echo "$GET_RESP" | jq -r '.name')
  if [ "$GET_NAME" == "Test AI" ]; then
    echo "✅ GET producto OK"
    PASS=$((PASS+1))
  else
    echo "❌ GET producto incorrecto"
    FAIL=$((FAIL+1))
  fi
fi

# Generar descripción con IA
GEN_RESP=$(curl -s -X POST "$BASE/generate" \
  -H "Content-Type: application/json" \
  -d '{"product_name":"Auriculares Bluetooth","features":"Cancelación de ruido, 30h batería"}')
DESC=$(echo "$GEN_RESP" | jq -r '.description')
if [ -n "$DESC" ] && [ "$DESC" != "null" ] && [ ${#DESC} -gt 10 ]; then
  echo "✅ Generación IA: '$DESC'"
  PASS=$((PASS+1))
else
  echo "❌ Generación IA falló: $GEN_RESP"
  FAIL=$((FAIL+1))
fi

# Traducción
TRANS_RESP=$(curl -s -X POST "$BASE/translate" \
  -H "Content-Type: application/json" \
  -d '{"text":"Hello world","target_lang":"Spanish"}')
TRANS=$(echo "$TRANS_RESP" | jq -r '.translated')
if [ -n "$TRANS" ] && [ "$TRANS" != "null" ]; then
  echo "✅ Traducción: '$TRANS'"
  PASS=$((PASS+1))
else
  echo "❌ Traducción falló: $TRANS_RESP"
  FAIL=$((FAIL+1))
fi

# Email marketing
EMAIL_RESP=$(curl -s -X POST "$BASE/email" \
  -H "Content-Type: application/json" \
  -d '{"product_name":"Zapatillas","features":"Ligeras, transpirables"}')
SUBJ=$(echo "$EMAIL_RESP" | jq -r '.subject')
BODY=$(echo "$EMAIL_RESP" | jq -r '.body')
if [ -n "$SUBJ" ] && [ "$SUBJ" != "null" ]; then
  echo "✅ Email generado: $SUBJ"
  PASS=$((PASS+1))
else
  echo "❌ Email falló: $EMAIL_RESP"
  FAIL=$((FAIL+1))
fi

echo ""
echo "=============================="
echo "✅ Pruebas exitosas: $PASS"
echo "❌ Pruebas fallidas: $FAIL"
echo "=============================="
