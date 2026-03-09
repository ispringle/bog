#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT="${1:-dist}"

sbcl --noinform \
     --eval "(require :asdf)" \
     --eval "(asdf:load-system :bog)" \
     --eval "(bog:generate :output #p\"${OUTPUT}/\")" \
     --eval "(uiop:quit 0)"
