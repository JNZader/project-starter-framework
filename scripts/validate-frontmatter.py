#!/usr/bin/env python3
"""validate-frontmatter.py

Simple frontmatter validator for `.ai-config` markdown files.
- Extracts YAML frontmatter at the top of the file
- Validates required fields: `name` (kebab-case) and `description` (non-empty)
- Uses JSON Schema (schemas/skill.schema.json or agent.schema.json) if jsonschema is available

Exit codes:
- 0 : valid
- 1 : invalid / missing frontmatter

This script prefers PyYAML if available; falls back to a lightweight parser
that handles common frontmatter patterns (single-line `key: value` and
simple block scalars for `description: |` or `>`).
"""
import re
import sys
import json
from pathlib import Path

KebabRe = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")

# Locate project root (two levels up from this script)
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
SCHEMAS_DIR = PROJECT_ROOT / "schemas"


def extract_frontmatter(text: str) -> str:
    lines = text.splitlines()
    if not lines:
        return ""
    if lines[0].strip() != '---':
        return ""
    # find second '---'
    for i in range(1, len(lines)):
        if lines[i].strip() == '---':
            return '\n'.join(lines[1:i])
    return ''


def simple_parse(fm: str) -> dict:
    data = {}
    lines = fm.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line.strip():
            i += 1
            continue
        m = re.match(r'^([A-Za-z0-9_-]+):\s*(.*)$', line)
        if not m:
            i += 1
            continue
        key = m.group(1)
        val = m.group(2)
        # handle block scalar for description
        if val in ('|', '>'):
            i += 1
            block = []
            while i < len(lines) and (lines[i].startswith(' ') or lines[i].startswith('\t')):
                block.append(lines[i].lstrip())
                i += 1
            data[key] = '\n'.join(block).strip()
            continue
        # strip quotes
        if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
            val = val[1:-1]
        data[key] = val.strip()
        i += 1
    return data


def parse_frontmatter(fm_text: str) -> dict:
    # prefer PyYAML if present
    try:
        import yaml  # type: ignore
    except Exception:
        return simple_parse(fm_text)
    try:
        parsed = yaml.safe_load(fm_text)
        if parsed is None:
            return {}
        if not isinstance(parsed, dict):
            return {}
        return parsed
    except Exception:
        return simple_parse(fm_text)


def load_schema(path: Path) -> dict | None:
    """Determine and load JSON Schema for the given file path."""
    try:
        path_str = str(path)
        if "/agents/" in path_str:
            schema_file = SCHEMAS_DIR / "agent.schema.json"
        else:
            schema_file = SCHEMAS_DIR / "skill.schema.json"
        if schema_file.exists():
            return json.loads(schema_file.read_text(encoding="utf-8"))
    except Exception:
        pass
    return None


def validate_with_schema(data: dict, schema: dict, path: Path) -> int:
    """Validate data against JSON Schema. Returns 0 on pass, 1 on fail."""
    try:
        import jsonschema  # type: ignore
        errors = list(jsonschema.Draft7Validator(schema).iter_errors(data))
        if errors:
            for err in errors:
                field = ".".join(str(p) for p in err.absolute_path) or err.path.root or "root"
                print(f"FAIL: schema error in {path} [{field}]: {err.message}")
            return 1
        print(f"PASS: schema valid for {path}")
        return 0
    except ImportError:
        # jsonschema not installed — fall back to basic check
        return None  # type: ignore


def validate_path(path: Path) -> int:
    txt = path.read_text(encoding='utf-8')
    fm = extract_frontmatter(txt)
    if not fm:
        print(f"FAIL: no frontmatter in {path}")
        return 1
    data = parse_frontmatter(fm)

    # Try JSON Schema validation first
    schema = load_schema(path)
    if schema:
        result = validate_with_schema(data, schema, path)
        if result is not None:
            return result
        # jsonschema not available — fall through to basic checks

    # Basic checks (fallback)
    name = data.get('name')
    desc = data.get('description')

    ok = True
    if not name:
        print(f"FAIL: missing 'name' in {path}")
        ok = False
    else:
        if not KebabRe.match(str(name)):
            print(f"FAIL: invalid 'name' (must be kebab-case) in {path} -> '{name}'")
            ok = False
        else:
            print(f"PASS: name ok for {path} -> '{name}'")

    if not desc:
        print(f"FAIL: missing or empty 'description' in {path}")
        ok = False
    else:
        print(f"PASS: description present for {path}")

    return 0 if ok else 1


def main(argv):
    if len(argv) < 2:
        print("Usage: validate-frontmatter.py <file.md>")
        return 2
    p = Path(argv[1])
    if not p.exists():
        print(f"File not found: {p}")
        return 2
    return validate_path(p)


if __name__ == '__main__':
    sys.exit(main(sys.argv))



def extract_frontmatter(text: str) -> str:
    lines = text.splitlines()
    if not lines:
        return ""
    if lines[0].strip() != '---':
        return ""
    # find second '---'
    for i in range(1, len(lines)):
        if lines[i].strip() == '---':
            return '\n'.join(lines[1:i])
    return ''


def simple_parse(fm: str) -> dict:
    data = {}
    lines = fm.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line.strip():
            i += 1
            continue
        m = re.match(r'^([A-Za-z0-9_-]+):\s*(.*)$', line)
        if not m:
            i += 1
            continue
        key = m.group(1)
        val = m.group(2)
        # handle block scalar for description
        if val in ('|', '>'):
            i += 1
            block = []
            while i < len(lines) and (lines[i].startswith(' ') or lines[i].startswith('\t')):
                block.append(lines[i].lstrip())
                i += 1
            data[key] = '\n'.join(block).strip()
            continue
        # strip quotes
        if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
            val = val[1:-1]
        data[key] = val.strip()
        i += 1
    return data


def parse_frontmatter(fm_text: str) -> dict:
    # prefer PyYAML if present
    try:
        import yaml  # type: ignore
    except Exception:
        return simple_parse(fm_text)
    try:
        parsed = yaml.safe_load(fm_text)
        if parsed is None:
            return {}
        if not isinstance(parsed, dict):
            return {}
        return parsed
    except Exception:
        return simple_parse(fm_text)


def validate_path(path: Path) -> int:
    txt = path.read_text(encoding='utf-8')
    fm = extract_frontmatter(txt)
    if not fm:
        print(f"FAIL: no frontmatter in {path}")
        return 1
    data = parse_frontmatter(fm)
    name = data.get('name')
    desc = data.get('description')

    ok = True
    if not name:
        print(f"FAIL: missing 'name' in {path}")
        ok = False
    else:
        if not KebabRe.match(str(name)):
            print(f"FAIL: invalid 'name' (must be kebab-case) in {path} -> '{name}'")
            ok = False
        else:
            print(f"PASS: name ok for {path} -> '{name}'")

    if not desc:
        print(f"FAIL: missing or empty 'description' in {path}")
        ok = False
    else:
        print(f"PASS: description present for {path}")

    return 0 if ok else 1


def main(argv):
    if len(argv) < 2:
        print("Usage: validate-frontmatter.py <file.md>")
        return 2
    p = Path(argv[1])
    if not p.exists():
        print(f"File not found: {p}")
        return 2
    return validate_path(p)


if __name__ == '__main__':
    sys.exit(main(sys.argv))
