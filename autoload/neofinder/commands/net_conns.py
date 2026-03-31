import platform

is_win = platform.system() == "Windows"

if is_win:
    data, err, rc = nf.sh("netstat -ano | findstr ESTABLISHED")
else:
    data, err, rc = nf.sh("ss -tunp 2>/dev/null || netstat -tunp 2>/dev/null")

if rc != 0:
    STDERR.print("Failed: %s" % err.strip())

lines = data.strip().splitlines()
STDOUT.print("Active Connections  (%d)" % len(lines))
STDOUT.print("=" * 60, "")
STDOUT.write(lines)
