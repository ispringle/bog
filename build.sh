#!/usr/bin/env bash
# This compiles a standalone binary server
set -euo pipefail

OUTPUT="${1:-bog-site}"
PORT="${2:-8080}"

echo "Building bog -> ${OUTPUT}"

sbcl --non-interactive \
     --eval '(require :asdf)' \
     --eval '(handler-bind ((warning #'\''muffle-warning))
               (asdf:load-system :bog))' \
     --eval "(bog:build :output #p\"${OUTPUT}\" :port ${PORT})"

echo "Done. Run with:"
echo "  ./${OUTPUT}"
echo "  BOG_PORT=3000 ./${OUTPUT}"
