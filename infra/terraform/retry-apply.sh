#!/usr/bin/env bash
#
# retry-apply.sh — retry terraform apply until the ARM instance is created.
#
# Why this exists:
#   Oracle Cloud Always Free gives VM.Standard.A1.Flex (ARM) the lowest
#   priority for capacity. In eu-madrid-1 it is common to receive
#   "Out of host capacity" or transient network errors (EOF, connection
#   reset, TLS handshake timeout). This script retries every 60s for up
#   to 24h until it succeeds.
#
# Usage:
#   nohup ./retry-apply.sh > /tmp/retry-apply.log 2>&1 &
#   tail -f /tmp/retry-apply.log
#
# Stop:
#   pkill -f retry-apply.sh
#
MAX_RETRIES=1440
RETRY_DELAY=60

for i in $(seq 1 $MAX_RETRIES); do
  echo "[$(date +%H:%M:%S)] Intento $i/$MAX_RETRIES..."
  terraform apply -auto-approve > /tmp/tf-apply.log 2>&1
  EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ] && grep -q "Apply complete!" /tmp/tf-apply.log; then
    echo "✅ ¡Instancia creada con éxito!"
    terraform output
    exit 0
  fi

  if grep -qiE "out of host capacity|InternalError|EOF|connection reset|timeout awaiting response|i/o timeout|TLS handshake timeout|Service Unavailable|429" /tmp/tf-apply.log; then
    echo "   Error transitorio. Reintentando en ${RETRY_DELAY}s..."
    sleep $RETRY_DELAY
  else
    echo "❌ Error no recuperable. Revisa /tmp/tf-apply.log"
    tail -20 /tmp/tf-apply.log
    exit 1
  fi
done
echo "❌ Se agotaron los reintentos."
exit 1
