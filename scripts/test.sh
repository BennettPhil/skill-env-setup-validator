#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT
PASS=0
FAIL=0

check() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc"
        echo "    expected: $expected"
        echo "    actual:   $actual"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== env-setup-validator tests ==="

# Test 1: detects bash (should exist on all systems)
cat > "$TMPDIR/test1.yaml" <<'EOF'
tools:
  - name: bash
    command: bash --version
EOF
result=$(python3 "$SCRIPT_DIR/validate.py" --manifest "$TMPDIR/test1.yaml" --format json)
status=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin)['tools'][0]['status'])")
check "detects bash" "pass" "$status"

# Test 2: detects missing tool
cat > "$TMPDIR/test2.yaml" <<'EOF'
tools:
  - name: nonexistent-tool-xyz
    command: nonexistent-tool-xyz --version
EOF
set +e
python3 "$SCRIPT_DIR/validate.py" --manifest "$TMPDIR/test2.yaml" --format json > "$TMPDIR/out2.json" 2>/dev/null
exit_code=$?
set -e
check "exits non-zero for missing tool" "1" "$exit_code"
status=$(python3 -c "import json; print(json.load(open('$TMPDIR/out2.json'))['tools'][0]['status'])")
check "reports fail for missing tool" "fail" "$status"

# Test 3: JSON output has summary
summary=$(python3 -c "import json; d=json.load(open('$TMPDIR/out2.json')); print(d['summary']['total'])")
check "JSON summary total" "1" "$summary"

# Test 4: missing manifest exits 2
set +e
python3 "$SCRIPT_DIR/validate.py" --manifest "$TMPDIR/no-such-file.yaml" 2>/dev/null
exit_code=$?
set -e
check "missing manifest exits 2" "2" "$exit_code"

# Test 5: --help exits 0
bash "$SCRIPT_DIR/run.sh" --help >/dev/null 2>&1 && help_code=0 || help_code=$?
check "--help exits 0" "0" "$help_code"

echo ""
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
