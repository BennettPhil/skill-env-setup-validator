#!/usr/bin/env python3
"""Environment setup validator."""

import argparse
import json
import re
import subprocess
import sys

def load_manifest(path):
    try:
        import yaml
    except ImportError:
        print("Missing dependency: pyyaml", file=sys.stderr)
        print("Install with: pip install pyyaml", file=sys.stderr)
        sys.exit(2)
    try:
        with open(path) as f:
            data = yaml.safe_load(f)
    except FileNotFoundError:
        print(f"Manifest not found: {path}", file=sys.stderr)
        sys.exit(2)
    except Exception as e:
        print(f"Error reading manifest: {e}", file=sys.stderr)
        sys.exit(2)
    if not isinstance(data, dict):
        print("Manifest must be a YAML mapping", file=sys.stderr)
        sys.exit(2)
    return data

def extract_version(text):
    match = re.search(r'(\d+\.\d+(?:\.\d+)?)', text)
    return match.group(1) if match else None

def parse_version(v):
    parts = v.split(".")
    return tuple(int(p) for p in parts)

def check_version(found, constraint):
    if not constraint:
        return True
    constraint = constraint.strip()
    if constraint.startswith(">="):
        req = constraint[2:]
        return parse_version(found) >= parse_version(req)
    elif constraint.startswith(">"):
        req = constraint[1:]
        return parse_version(found) > parse_version(req)
    elif constraint.startswith("="):
        req = constraint[1:]
        return parse_version(found) == parse_version(req)
    else:
        return parse_version(found) == parse_version(constraint)

def check_tool(tool):
    name = tool["name"]
    command = tool.get("command", f"{name} --version")
    required = tool.get("version", "")
    try:
        result = subprocess.run(
            command, shell=True, capture_output=True, text=True, timeout=10
        )
        output = result.stdout + result.stderr
        found = extract_version(output)
        if found is None:
            if result.returncode == 0:
                return {"name": name, "status": "pass", "found_version": "unknown", "required_version": required or "any"}
            return {"name": name, "status": "fail", "found_version": "not found", "required_version": required or "any"}
        if required and not check_version(found, required):
            return {"name": name, "status": "fail", "found_version": found, "required_version": required}
        return {"name": name, "status": "pass", "found_version": found, "required_version": required or "any"}
    except subprocess.TimeoutExpired:
        return {"name": name, "status": "fail", "found_version": "timeout", "required_version": required or "any"}
    except Exception as e:
        return {"name": name, "status": "fail", "found_version": str(e), "required_version": required or "any"}

def check_service(svc):
    name = svc["name"]
    command = svc.get("check", "")
    if not command:
        return {"name": name, "status": "fail", "error": "no check command"}
    try:
        result = subprocess.run(
            command, shell=True, capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0:
            return {"name": name, "status": "pass"}
        error = (result.stderr or result.stdout).strip()[:80]
        return {"name": name, "status": "fail", "error": error}
    except subprocess.TimeoutExpired:
        return {"name": name, "status": "fail", "error": "timeout"}
    except Exception as e:
        return {"name": name, "status": "fail", "error": str(e)}

def format_text(tool_results, svc_results):
    lines = []
    if tool_results:
        lines.append(f"{'Tool':<12} {'Status':<8} {'Found':<12} {'Required'}")
        lines.append(f"{'----':<12} {'------':<8} {'-----':<12} {'--------'}")
        for t in tool_results:
            status = "PASS" if t["status"] == "pass" else "FAIL"
            lines.append(f"{t['name']:<12} {status:<8} {t['found_version']:<12} {t['required_version']}")
    if svc_results:
        lines.append("")
        lines.append(f"{'Service':<12} {'Status':<8} {'Details'}")
        lines.append(f"{'-------':<12} {'------':<8} {'-------'}")
        for s in svc_results:
            status = "PASS" if s["status"] == "pass" else "FAIL"
            detail = s.get("error", "")
            lines.append(f"{s['name']:<12} {status:<8} {detail}")
    total = len(tool_results) + len(svc_results)
    passed = sum(1 for t in tool_results if t["status"] == "pass") + sum(1 for s in svc_results if s["status"] == "pass")
    failed = total - passed
    lines.append("")
    lines.append(f"Summary: {passed}/{total} passed, {failed} failed")
    return "\n".join(lines)

def format_json(tool_results, svc_results):
    total = len(tool_results) + len(svc_results)
    passed = sum(1 for t in tool_results if t["status"] == "pass") + sum(1 for s in svc_results if s["status"] == "pass")
    return json.dumps({
        "tools": tool_results,
        "services": svc_results,
        "summary": {"total": total, "passed": passed, "failed": total - passed}
    }, indent=2)

def main():
    parser = argparse.ArgumentParser(description="Validate developer environment")
    parser.add_argument("--manifest", default=".env-check.yaml")
    parser.add_argument("--format", choices=["text", "json"], default="text")
    args = parser.parse_args()

    data = load_manifest(args.manifest)
    tools = data.get("tools", [])
    services = data.get("services", [])

    tool_results = [check_tool(t) for t in tools]
    svc_results = [check_service(s) for s in services]

    if args.format == "json":
        print(format_json(tool_results, svc_results))
    else:
        print(format_text(tool_results, svc_results))

    any_failed = any(t["status"] == "fail" for t in tool_results) or any(s["status"] == "fail" for s in svc_results)
    sys.exit(1 if any_failed else 0)

if __name__ == "__main__":
    main()
