#!/bin/bash
set -e
for f in docs/architecture/*.mmd; do
  mmdc -i "$f" -o "${f%.mmd}.svg"
done
