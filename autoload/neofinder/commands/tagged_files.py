groups = nf.tags.groups()

if not groups:
    nf.echo("No tags. Use <Leader>ft to tag files.")
else:
    out = ["Tagged Files", "=" * 40, ""]
    for g in groups:
        out.append("[%s]" % g)
        for f in nf.tags.files(g):
            out.append("  %s" % f)
        out.append("")
    nf.out.write(out)
