"""
NeoFinder TOML parser -- reads config.toml, returns dict to Vim.

Supports the subset of TOML that config needs:
  - Sections: [section]
  - Strings: key = "value"
  - Numbers: key = 42
  - Booleans: key = true / false
  - Arrays: key = ["a", "b"]  (single line)
  - Comments: # ignored
  - Nested sections: [section.sub]
"""

import os
import re
import json


def parse_toml(path):
    """Parse a TOML file, return a nested dict."""
    if not os.path.isfile(path):
        return {}

    with open(path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    result = {}
    current_section = result

    # Track section path for nested sections
    section_path = []

    for raw_line in lines:
        line = raw_line.strip()

        # Skip empty lines and comments
        if not line or line.startswith('#'):
            continue

        # Strip inline comments (but not inside strings)
        if '#' in line:
            in_string = False
            for i, ch in enumerate(line):
                if ch == '"' and (i == 0 or line[i-1] != '\\'):
                    in_string = not in_string
                elif ch == '#' and not in_string:
                    line = line[:i].rstrip()
                    break

        # Section header: [name] or [name.sub]
        m = re.match(r'^\[([^\]]+)\]$', line)
        if m:
            section_path = m.group(1).split('.')
            current_section = result
            for part in section_path:
                part = part.strip()
                if part not in current_section:
                    current_section[part] = {}
                current_section = current_section[part]
            continue

        # Key = Value
        m = re.match(r'^(\w+)\s*=\s*(.+)$', line)
        if m:
            key = m.group(1)
            val = m.group(2).strip()
            current_section[key] = _parse_value(val)

    return result


def _parse_value(val):
    """Parse a TOML value string into a Python object."""
    # Boolean
    if val == 'true':
        return True
    if val == 'false':
        return False

    # Integer
    if re.match(r'^-?\d+$', val):
        return int(val)

    # Float
    if re.match(r'^-?\d+\.\d+$', val):
        return float(val)

    # String (double-quoted)
    if val.startswith('"') and val.endswith('"'):
        return val[1:-1].replace('\\"', '"').replace('\\\\', '\\')

    # Single-quoted string
    if val.startswith("'") and val.endswith("'"):
        return val[1:-1]

    # Array (single line)
    if val.startswith('[') and val.endswith(']'):
        inner = val[1:-1].strip()
        if not inner:
            return []
        items = []
        # Simple split by comma (handles strings with commas inside quotes)
        current = ''
        in_string = False
        for ch in inner:
            if ch == '"' and (not current or current[-1] != '\\'):
                in_string = not in_string
                current += ch
            elif ch == ',' and not in_string:
                items.append(_parse_value(current.strip()))
                current = ''
            else:
                current += ch
        if current.strip():
            items.append(_parse_value(current.strip()))
        return items

    # Fallback: return as string
    return val


def load_config(path):
    """Parse TOML and return as JSON string for Vim."""
    data = parse_toml(path)
    return json.dumps(data)
