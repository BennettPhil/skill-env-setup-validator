# env-setup-validator

Validate local developer environment tools and versions against a JSON manifest.

## Quick Start
Create `.env-setup-manifest.json`:

```json
{
  "tools": [
    { "name": "node", "version_command": "node --version", "version_regex": "^v20\\." },
    { "name": "pnpm", "version_command": "pnpm --version", "version_regex": "^9\\." }
  ]
}
```

Run validation:
```bash
./scripts/run.sh --manifest .env-setup-manifest.json --format text
```

Fail CI when issues are found:
```bash
./scripts/run.sh --manifest .env-setup-manifest.json --strict --format json
```
