#!/bin/bash
# Usage: ./scripts/migrate.sh [up|down]
DIRECTION=${1:-up}
if [ "$DIRECTION" = "up" ]; then
  echo "Applying migrations..."
  go run cmd/migrate/main.go up
elif [ "$DIRECTION" = "down" ]; then
  echo "Rolling back migrations..."
  go run cmd/migrate/main.go down
else
  echo "Unknown direction: $DIRECTION"
fi
