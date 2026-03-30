import platform

is_win = platform.system() == "Windows"

STDOUT.print("Network Info", "=" * 50, "")

# Interfaces & IPs
STDOUT.print("[INTERFACES]")
if is_win:
    data, err, rc = nf.sh("ipconfig")
else:
    data, err, rc = nf.sh("ip -br addr 2>/dev/null || ifconfig 2>/dev/null")
STDOUT.write(data.splitlines())
if rc != 0:
    STDERR.print("Could not get interfaces: %s" % err.strip())
STDOUT.print("")

# Routes
STDOUT.print("[ROUTES]")
if is_win:
    data, err, rc = nf.sh("route print -4")
else:
    data, err, rc = nf.sh("ip route 2>/dev/null || netstat -rn 2>/dev/null")
STDOUT.write(data.splitlines())
STDOUT.print("")

# DNS
STDOUT.print("[DNS]")
if is_win:
    data, _, _ = nf.sh("ipconfig /all | findstr DNS")
else:
    data, _, _ = nf.sh("cat /etc/resolv.conf 2>/dev/null | grep -v '^#'")
STDOUT.write(data.splitlines())
STDOUT.print("")

# Listening ports
STDOUT.print("[LISTENING PORTS]")
if is_win:
    data, _, _ = nf.sh("netstat -an | findstr LISTENING")
else:
    data, _, _ = nf.sh("ss -tlnp 2>/dev/null || netstat -tlnp 2>/dev/null")
STDOUT.write(data.splitlines())
