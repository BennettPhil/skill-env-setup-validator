#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat >&2 <<'EOF'
Usage: run.sh [OPTIONS]

Validate developer environment against a requirements manifest.

Options:
    --manifest FILE   Path to manifest (default: .env-check.yaml)
    --format text|json Output format (default: text)
    -h, --help        Show this help message
EOF
    exit "${1:-0}"
}

MANIFEST=".env-check.yaml"
FORMAT="text"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --manifest) MANIFEST="$2"; shift 2 ;;
        --format) FORMAT="$2"; shift 2 ;;
        -h|--help) usage 0 ;;
        -*) echo "Unknown option: $1" >&2; usage 1 ;;
        *) echo "Unexpected argument: $1" >&2; usage 1 ;;
    esac
done

exec python3 "$SCRIPT_DIR/validate.py" --manifest "$MANIFEST" --format "$FORMAT"
