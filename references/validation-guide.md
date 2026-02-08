# Validation Guide

## How Checks Work

### Tool Checks

For each entry in `tools:`, the validator:

1. Runs the specified `command` (default: `<name> --version`)
2. Captures stdout and stderr
3. Extracts a version number using the regex `(\d+\.\d+(\.\d+)?)`
4. If `version` is specified, compares using semver rules
5. Reports PASS if the tool exists and version satisfies the constraint

### Version Constraints

Supported operators:
- `>=X.Y.Z` — minimum version (inclusive)
- `>X.Y.Z` — minimum version (exclusive)
- `=X.Y.Z` or `X.Y.Z` — exact match
- No version specified — only checks existence

### Service Checks

For each entry in `services:`, the validator:

1. Runs the `check` command
2. If exit code is 0, reports PASS
3. If non-zero or timeout (5s), reports FAIL with the error output

### JSON Output Schema

```json
{
  "tools": [
    {
      "name": "node",
      "status": "pass",
      "found_version": "20.11.0",
      "required_version": ">=18.0.0"
    }
  ],
  "services": [
    {
      "name": "postgresql",
      "status": "pass"
    }
  ],
  "summary": {
    "total": 5,
    "passed": 4,
    "failed": 1
  }
}
```

## Verification

Run `./scripts/test.sh` to execute the built-in test suite against a sample manifest.

```bash
./scripts/test.sh
```

Expected: all tests pass on a machine with bash 4+ and basic Unix tools.
