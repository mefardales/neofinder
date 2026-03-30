result = nf.sh_lines('grep -rn "%s" . 2>/dev/null | head -100' % pattern)
nf.out.write(result)
