#!/usr/bin/env bash
set -euo pipefail

manifest=".env-setup-manifest.json"
format="text"
strict=0

usage() {
  cat <<'EOF'
Usage: run.sh [--manifest PATH] [--format text|json] [--strict]

Validate local toolchain setup against a manifest file.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --manifest) manifest="$2"; shift 2 ;;
    --format) format="$2"; shift 2 ;;
    --strict) strict=1; shift ;;
    --help) usage; exit 0 ;;
    *) echo "run.sh: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if ! command -v jq >/dev/null 2>&1; then
  echo "run.sh: jq is required" >&2
  exit 2
fi

if [[ ! -f "$manifest" ]]; then
  echo "run.sh: manifest not found: $manifest" >&2
  exit 2
fi

if ! jq -e '.tools and (.tools | type == "array")' "$manifest" >/dev/null 2>&1; then
  echo "run.sh: invalid manifest format (expected .tools array)" >&2
  exit 2
fi

tmp_results="$(mktemp)"
trap 'rm -f "$tmp_results"' EXIT

issues=0
while IFS= read -r tool; do
  name="$(jq -r '.name // empty' <<<"$tool")"
  version_command="$(jq -r '.version_command // empty' <<<"$tool")"
  version_regex="$(jq -r '.version_regex // ".*"' <<<"$tool")"

  if [[ -z "$name" || -z "$version_command" ]]; then
    echo "run.sh: manifest tool entries require name and version_command" >&2
    exit 2
  fi

  set +e
  output="$(bash -lc "$version_command" 2>&1)"
  cmd_status=$?
  set -e

  status="ok"
  note=""
  if [[ "$cmd_status" -ne 0 || -z "$output" ]]; then
    status="missing"
    note="command failed"
  elif ! grep -Eq "$version_regex" <<<"$output"; then
    status="outdated"
    note="version does not match regex"
  fi

  if [[ "$status" != "ok" ]]; then
    issues=$((issues + 1))
  fi

  jq -nc --arg name "$name" --arg command "$version_command" --arg regex "$version_regex" --arg status "$status" --arg output "$output" --arg note "$note" \
    '{name:$name,version_command:$command,version_regex:$regex,status:$status,detected:$output,note:$note}' >>"$tmp_results"
done < <(jq -c '.tools[]' "$manifest")

if [[ "$format" == "json" ]]; then
  jq -s --argjson issues "$issues" '{issues:$issues,results:.}' "$tmp_results"
else
  echo "Environment validation report"
  echo "manifest: $manifest"
  echo ""
  jq -r '"\(.name)\t\(.status)\t\(.detected)\t\(.note)"' "$tmp_results" | while IFS=$'\t' read -r name status detected note; do
    echo "- $name: $status"
    echo "  detected: $detected"
    [[ -n "$note" ]] && echo "  note: $note"
  done
  echo ""
  echo "issues=$issues"
fi

if [[ "$strict" -eq 1 && "$issues" -gt 0 ]]; then
  exit 1
fi
