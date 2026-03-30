lines = sorted(STDIN.lines)
nf.buf.write(lines)
nf.echo("Sorted %d lines" % len(lines))
