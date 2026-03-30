import platform
import socket

STDOUT.print("Scanning %s..." % host)
STDOUT.print("=" * 50, "")

is_win = platform.system() == "Windows"

# Ping
STDOUT.print("[PING]")
if is_win:
    ping_out, ping_err, rc = nf.sh("ping -n 3 %s" % host)
else:
    ping_out, ping_err, rc = nf.sh("ping -c 3 -W 2 %s" % host)
STDOUT.write(ping_out.splitlines())
if rc != 0:
    STDERR.print("Ping failed: %s" % (ping_err.strip() or "host unreachable"))
STDOUT.print("")

# DNS resolve
STDOUT.print("[DNS]")
try:
    ip = socket.gethostbyname(host)
    STDOUT.print("  %s -> %s" % (host, ip))
    try:
        reverse = socket.gethostbyaddr(ip)[0]
        STDOUT.print("  %s -> %s (reverse)" % (ip, reverse))
    except socket.herror:
        pass
except socket.gaierror:
    STDERR.print("DNS: could not resolve %s" % host)
STDOUT.print("")

# Common ports
STDOUT.print("[COMMON PORTS]")
ports = [21, 22, 23, 25, 53, 80, 110, 143, 443, 445, 993, 995, 3306, 3389, 5432, 8080, 8443]
open_count = 0
for port in ports:
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(0.5)
        result = s.connect_ex((host, port))
        if result == 0:
            try:
                service = socket.getservbyport(port)
            except OSError:
                service = "unknown"
            STDOUT.print("  %-6d open   %s" % (port, service))
            open_count += 1
        s.close()
    except (socket.timeout, OSError):
        pass

STDOUT.print("")
STDOUT.print("Found %d open ports" % open_count)
