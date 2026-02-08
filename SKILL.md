---
name: env-setup-validator
description: Validate developer machine tools/versions against a manifest file.
version: 0.1.0
license: Apache-2.0
---

# Environment Setup Validator

## Purpose
This skill checks whether a developer machine has required tools installed and validates versions against project requirements defined in a manifest file.

## Instructions
1. Create a manifest JSON file listing required tools and version patterns.
2. Run `./scripts/run.sh --manifest <path>` to validate installed tools.
3. Use `--format json` for machine-readable output.
4. Use `--strict` to fail the command if any tool is missing or has a non-matching version.

## Inputs
- `--manifest <path>`: path to manifest JSON (default `.env-setup-manifest.json`)
- `--format text|json`: output format (default `text`)
- `--strict`: return non-zero when issues exist

Manifest schema:
```json
{
  "tools": [
    { "name": "node", "version_command": "node --version", "version_regex": "^v20\\." },
    { "name": "pnpm", "version_command": "pnpm --version", "version_regex": "^9\\." }
  ]
}
```

## Outputs
- Text or JSON report listing each tool status:
- `ok`: installed and version matches
- `outdated`: installed but version regex mismatch
- `missing`: command unavailable or execution failed
- Exit code `0` on success, `1` when `--strict` and issues found, `2` for invalid manifest/usage

## Constraints
- Requires `jq` to parse manifest JSON.
- Version checks depend on command output format.
- Command execution uses `bash -lc`; manifest commands must be safe and trusted.
