---
name: env-setup-validator
description: Validates that a developer machine has all required tools, runtimes, and services for a project by checking a manifest file.
version: 0.1.0
license: Apache-2.0
---

# Environment Setup Validator

Checks a developer's machine against a project requirements manifest and reports missing tools, wrong versions, and unavailable services.

## Constraints

- Reads requirements from a `.env-check.yaml` manifest in the project root.
- Only checks; never installs or modifies the system.
- Exit code 0 if all checks pass, 1 if any check fails, 2 on manifest errors.

## Usage

```bash
# Check current directory for .env-check.yaml and validate
./scripts/run.sh

# Check a specific manifest
./scripts/run.sh --manifest path/to/.env-check.yaml

# JSON output for CI integration
./scripts/run.sh --format json
```

## Manifest Format

```yaml
tools:
  - name: node
    command: node --version
    version: ">=18.0.0"
  - name: python3
    command: python3 --version
    version: ">=3.10"
  - name: docker
    command: docker --version

services:
  - name: postgresql
    check: pg_isready -h localhost -p 5432
  - name: redis
    check: redis-cli ping
```

## Output

Human-readable table by default:

```
Tool        Status   Found      Required
----        ------   -----      --------
node        PASS     v20.11.0   >=18.0.0
python3     PASS     3.12.1     >=3.10
docker      PASS     24.0.7     any
git         FAIL     not found  any

Service     Status
-------     ------
postgresql  PASS
redis       FAIL     connection refused
```

## Options

- `--manifest FILE` — Path to manifest (default: `.env-check.yaml`)
- `--format text|json` — Output format (default: `text`)
- `--help` — Show usage information

## Limitations

- Version comparison supports semver-like versions only (major.minor.patch).
- Service checks rely on the service's own CLI client being available.
- Does not support Windows; designed for macOS and Linux.
