#!/usr/bin/env python3
"""validate-frontmatter.py

Simple frontmatter validator for `.ai-config` markdown files.
- Extracts YAML frontmatter at the top of the file
- Validates required fields: `name` (kebab-case) and `description` (non-empty)

Exit codes:
- 0 : valid
- 1 : invalid / missing frontmatter

This script prefers PyYAML if available; falls back to a lightweight parser
that handles common frontmatter patterns (single-line `key: value` and
simple block scalars for `description: |` or `>`).
"""
import re
import sys
from pathlib import Path

KebabRe = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")


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
