# ── OpenPorts ─────────────────────────────────────────────
# Shows open ports with process, PID, user, and state info.
# Uses lsof + netstat/ss for cross-reference.
# Variables injected: filter, hostname, timestamp, is_mac

import re
from collections import defaultdict

# Default filter if empty or invalid
if filter not in ("all", "tcp", "udp", "listening"):
    filter = "all"

STDOUT.print("  Host: %s" % hostname)
STDOUT.print("  Time: %s" % timestamp)
STDOUT.print("  Filter: %s" % filter)
STDOUT.print("")

# ── Gather data via lsof ────────────────────────────────
if filter == "tcp":
    lsof_cmd = "lsof -iTCP -nP 2>/dev/null"
elif filter == "udp":
    lsof_cmd = "lsof -iUDP -nP 2>/dev/null"
elif filter == "listening":
    lsof_cmd = "lsof -iTCP -sTCP:LISTEN -nP 2>/dev/null"
else:
    lsof_cmd = "lsof -i -nP 2>/dev/null"

stdout, stderr, rc = nf.sh(lsof_cmd)

if rc != 0 and not stdout:
    STDERR.print("lsof failed (try running vim with sudo for full results)")
    STDERR.print(stderr.strip() if stderr else "unknown error")

# ── Parse lsof output ───────────────────────────────────
entries = []
seen = set()

for line in stdout.splitlines()[1:]:  # skip header
    parts = line.split()
    if len(parts) < 9:
        continue

    proc = parts[0]
    pid = parts[1]
    user = parts[2]
    fd = parts[3]
    proto = parts[7] if len(parts) > 7 else parts[4]
    name = parts[8] if len(parts) > 8 else parts[-1]

    # Extract state if present (LISTEN, ESTABLISHED, etc.)
    state = ""
    if len(parts) > 9:
        state = parts[9].strip("()")
    elif "LISTEN" in line:
        state = "LISTEN"
    elif "ESTABLISHED" in line:
        state = "ESTABLISHED"
    elif "CLOSE_WAIT" in line:
        state = "CLOSE_WAIT"
    elif "TIME_WAIT" in line:
        state = "TIME_WAIT"

    # Parse address:port
    local = ""
    remote = ""
    if "->" in name:
        local, remote = name.split("->", 1)
    else:
        local = name

    # Extract port from local address
    port = ""
    if ":" in local:
        port = local.rsplit(":", 1)[-1]

    # Deduplicate by pid+port+proto
    key = "%s:%s:%s" % (pid, port, proto)
    if key in seen:
        continue
    seen.add(key)

    # Detect protocol
    if "TCP" in proto or "tcp" in proto.lower():
        proto_clean = "TCP"
    elif "UDP" in proto or "udp" in proto.lower():
        proto_clean = "UDP"
    else:
        proto_clean = proto[:5]

    entries.append({
        'proto': proto_clean,
        'port': port,
        'local': local,
        'remote': remote,
        'state': state,
        'pid': pid,
        'process': proc,
        'user': user,
    })

# ── Sort: listening first, then by port number ──────────
def sort_key(e):
    is_listen = 0 if e['state'] == 'LISTEN' else 1
    try:
        port_num = int(e['port'])
    except (ValueError, TypeError):
        port_num = 99999
    return (is_listen, port_num, e['proto'])

entries.sort(key=sort_key)

# ── Format output ───────────────────────────────────────
if not entries:
    STDOUT.print("  No open ports detected.")
    STDOUT.print("  (Run vim with sudo for complete results)")
else:
    # Table header
    STDOUT.print("  %-6s %-7s %-24s %-24s %-13s %-7s %-12s %s" % (
        "PROTO", "PORT", "LOCAL", "REMOTE", "STATE", "PID", "PROCESS", "USER"))
    STDOUT.print("  " + "─" * 88)

    # Group by state for summary
    by_state = defaultdict(int)
    by_proto = defaultdict(int)

    for e in entries:
        by_state[e['state'] or 'unknown'] += 1
        by_proto[e['proto']] += 1

        # Color-code state via markers
        state_display = e['state'] or "·"

        remote_display = e['remote'] if e['remote'] else "·"
        if len(remote_display) > 24:
            remote_display = remote_display[:21] + "..."

        local_display = e['local']
        if len(local_display) > 24:
            local_display = local_display[:21] + "..."

        STDOUT.print("  %-6s %-7s %-24s %-24s %-13s %-7s %-12s %s" % (
            e['proto'],
            e['port'] or "·",
            local_display,
            remote_display,
            state_display,
            e['pid'],
            e['process'][:12],
            e['user'],
        ))

    # ── Summary ─────────────────────────────────────────
    STDOUT.print("")
    STDOUT.print("  " + "═" * 88)
    STDOUT.print("")

    total = len(entries)
    STDOUT.print("  SUMMARY: %d connections" % total)
    STDOUT.print("")

    # By state
    STDOUT.print("  By state:")
    for state, count in sorted(by_state.items(), key=lambda x: -x[1]):
        bar = "█" * min(count, 40)
        STDOUT.print("    %-15s %3d  %s" % (state, count, bar))

    STDOUT.print("")

    # By protocol
    STDOUT.print("  By protocol:")
    for proto, count in sorted(by_proto.items()):
        bar = "█" * min(count, 40)
        STDOUT.print("    %-6s %3d  %s" % (proto, count, bar))

    STDOUT.print("")

    # Listening ports highlight
    listening = [e for e in entries if e['state'] == 'LISTEN']
    if listening:
        STDOUT.print("  Listening services (%d):" % len(listening))
        for e in listening:
            STDOUT.print("    :%s/%s  →  %s (pid %s, %s)" % (
                e['port'], e['proto'].lower(), e['process'], e['pid'], e['user']))
        STDOUT.print("")

    # Established connections
    established = [e for e in entries if e['state'] == 'ESTABLISHED']
    if established:
        STDOUT.print("  Active connections (%d):" % len(established))
        remotes = defaultdict(int)
        for e in established:
            remote_host = e['remote'].rsplit(":", 1)[0] if e['remote'] else "unknown"
            remotes[remote_host] += 1
        for host, count in sorted(remotes.items(), key=lambda x: -x[1])[:10]:
            STDOUT.print("    %-40s  %d conn" % (host, count))

STDOUT.print("")
STDOUT.print("  ─ scan complete ─")
