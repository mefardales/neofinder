"""
NeoFinder Python Runtime -- injected before every Python command.

Provides the `nf` object with full access to:
  - Buffer read/write (nf.buf)
  - Output scratch buffer (nf.out)
  - Shell execution (nf.sh)
  - User input (nf.input, nf.select)
  - Tags & groups (nf.tags)
  - Editor context (nf.file, nf.dir, nf.line, etc.)
  - File operations (nf.open, nf.vsplit, nf.split)
"""

import vim as _vim
import subprocess as _subprocess
import json as _json
import os as _os


def _esc(s):
    """Escape a string for Vim command interpolation."""
    return str(s).replace('\\', '\\\\').replace('"', '\\"')


# =========================================================================
#  nf.buf -- Current buffer read/write
# =========================================================================
class _Buffer:
    """Read and write the current Vim buffer."""

    @property
    def lines(self):
        """All lines as a list of strings."""
        return list(_vim.current.buffer)

    @property
    def text(self):
        """Full buffer as a single string."""
        return '\n'.join(_vim.current.buffer)

    @property
    def name(self):
        """Buffer filename (full path)."""
        return _vim.eval('expand("%:p")')

    @property
    def filetype(self):
        return _vim.eval('&filetype')

    @property
    def line(self):
        """Current line text."""
        return _vim.current.line

    @line.setter
    def line(self, value):
        _vim.current.line = str(value)

    @property
    def line_number(self):
        """Current line number (1-based)."""
        return int(_vim.eval('line(".")'))

    @property
    def col(self):
        """Current column (1-based)."""
        return int(_vim.eval('col(".")'))

    @property
    def selection(self):
        """Visual selection as list of lines (empty if no selection)."""
        start = int(_vim.eval("line(\"'<\")"))
        end = int(_vim.eval("line(\"'>\")"))
        if start > 0 and end > 0 and start <= end:
            return list(_vim.current.buffer[start - 1:end])
        return []

    def write(self, content):
        """Replace entire buffer content. Accepts string or list of lines."""
        if isinstance(content, str):
            content = content.split('\n')
        buf = _vim.current.buffer
        buf[:] = content

    def append(self, content):
        """Append to end of buffer. Accepts string or list of lines."""
        if isinstance(content, str):
            content = content.split('\n')
        buf = _vim.current.buffer
        for line in content:
            buf.append(str(line))

    def insert(self, content, line_nr=None):
        """Insert at line number (1-based). Default: current line."""
        if isinstance(content, str):
            content = content.split('\n')
        if line_nr is None:
            line_nr = self.line_number
        buf = _vim.current.buffer
        for i, ln in enumerate(content):
            buf.append(str(ln), line_nr - 1 + i)

    def clear(self):
        """Clear all buffer content."""
        _vim.current.buffer[:] = ['']

    def __len__(self):
        return len(_vim.current.buffer)

    def __getitem__(self, idx):
        return _vim.current.buffer[idx]

    def __setitem__(self, idx, value):
        _vim.current.buffer[idx] = str(value)


# =========================================================================
#  nf.out -- Output scratch buffer
# =========================================================================
class _Output:
    """Manage a scratch output buffer for displaying results."""

    def __init__(self):
        self._bufnr = -1

    def _ensure(self, title='[NeoFinder Output]'):
        """Create or switch to the output scratch buffer."""
        # If buffer exists and is valid, switch to it
        if self._bufnr > 0 and int(_vim.eval('bufexists(%d)' % self._bufnr)):
            winid = int(_vim.eval('bufwinid(%d)' % self._bufnr))
            if winid > 0:
                _vim.eval('win_gotoid(%d)' % winid)
            else:
                _vim.command('sbuffer %d' % self._bufnr)
            return
        # Create new scratch buffer
        _vim.command('botright new')
        _vim.command('setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile')
        _vim.command('setlocal nowrap nonumber norelativenumber')
        _vim.command('file ' + _esc(title))
        self._bufnr = int(_vim.eval('bufnr("%")'))

    def write(self, content, title='[NeoFinder Output]'):
        """Replace output buffer content. Creates buffer if needed."""
        self._ensure(title)
        if isinstance(content, str):
            content = content.split('\n')
        _vim.command('setlocal modifiable')
        _vim.current.buffer[:] = [str(l) for l in content]
        _vim.command('setlocal nomodifiable')

    def append(self, content):
        """Append lines to the output buffer."""
        self._ensure()
        if isinstance(content, str):
            content = content.split('\n')
        _vim.command('setlocal modifiable')
        for line in content:
            _vim.current.buffer.append(str(line))
        _vim.command('setlocal nomodifiable')

    def clear(self):
        """Clear the output buffer."""
        if self._bufnr > 0 and int(_vim.eval('bufexists(%d)' % self._bufnr)):
            winid = int(_vim.eval('bufwinid(%d)' % self._bufnr))
            if winid > 0:
                _vim.eval('win_gotoid(%d)' % winid)
                _vim.command('setlocal modifiable')
                _vim.current.buffer[:] = ['']
                _vim.command('setlocal nomodifiable')

    def close(self):
        """Close the output buffer."""
        if self._bufnr > 0 and int(_vim.eval('bufexists(%d)' % self._bufnr)):
            _vim.command('bwipeout! %d' % self._bufnr)
            self._bufnr = -1


# =========================================================================
#  nf.tags -- Tag groups
# =========================================================================
class _Tags:
    """Access NeoFinder tag groups."""

    def groups(self):
        """List of group names."""
        raw = _vim.eval('neofinder#tags#list_groups()')
        return [line.split()[0] for line in raw]

    def files(self, group='default'):
        """Files in a specific group."""
        return _vim.eval("neofinder#tags#list_by_group('%s')" % _esc(group))

    def all(self):
        """All tagged files (flat list)."""
        return _vim.eval('neofinder#tags#list()')

    def add(self, path, group='default'):
        """Tag a file to a group."""
        _vim.command("call neofinder#tags#add('%s', '%s')" % (_esc(path), _esc(group)))

    def remove(self, path):
        """Remove a file from all groups."""
        _vim.command("call neofinder#tags#remove('%s')" % _esc(path))


# =========================================================================
#  Main nf object
# =========================================================================
class _NeoFinder:

    def __init__(self):
        self.buf = _Buffer()
        self.out = _Output()
        self.tags = _Tags()

    # -- Editor context (read-only shortcuts) --

    @property
    def file(self):
        """Current file full path."""
        return _vim.eval('expand("%:p")')

    @property
    def filename(self):
        """Current file name (tail only)."""
        return _vim.eval('expand("%:t")')

    @property
    def dir(self):
        """Current working directory."""
        return _vim.eval('getcwd()')

    @property
    def line(self):
        """Current line text."""
        return _vim.current.line

    @property
    def filetype(self):
        return _vim.eval('&filetype')

    @property
    def theme(self):
        return _vim.eval('get(g:neofinder, "theme", "matrix")')

    # -- Shell execution --

    def sh(self, cmd):
        """Run a shell command. Returns (stdout, stderr, returncode)."""
        r = _subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return r.stdout, r.stderr, r.returncode

    def sh_output(self, cmd, title=None):
        """Run a shell command and put stdout in the output buffer."""
        if title is None:
            title = '[$ %s]' % cmd[:40]
        stdout, stderr, rc = self.sh(cmd)
        lines = stdout.splitlines()
        if rc != 0 and stderr:
            lines.append('')
            lines.append('--- stderr (exit %d) ---' % rc)
            lines += stderr.splitlines()
        self.out.write(lines, title)
        return stdout

    def sh_lines(self, cmd):
        """Run a shell command. Returns stdout lines as a list."""
        stdout, _, _ = self.sh(cmd)
        return stdout.strip().splitlines()

    # -- User interaction --

    def input(self, prompt='> '):
        """Ask the user for text input. Returns string."""
        return _vim.eval("input('%s')" % _esc(prompt))

    def confirm(self, msg, choices='&Yes\n&No', default=1):
        """Ask the user to confirm. Returns 1-based choice index."""
        return int(_vim.eval("confirm('%s', '%s', %d)" % (_esc(msg), _esc(choices), default)))

    def select(self, items, prompt='Select: '):
        """Show a numbered list and let user pick. Returns selected string or None."""
        lines = ['%d. %s' % (i + 1, item) for i, item in enumerate(items)]
        _vim.command('echohl NeoFinderPrompt')
        for l in lines:
            _vim.command("echo '%s'" % _esc(l))
        _vim.command('echohl None')
        choice = self.input(prompt)
        try:
            idx = int(choice) - 1
            if 0 <= idx < len(items):
                return items[idx]
        except (ValueError, IndexError):
            pass
        return None

    # -- File operations --

    def open(self, path):
        """Open a file in the current window."""
        _vim.command('edit %s' % _esc(path))

    def vsplit(self, path):
        """Open a file in a vertical split."""
        _vim.command('vsplit %s' % _esc(path))

    def split(self, path):
        """Open a file in a horizontal split."""
        _vim.command('split %s' % _esc(path))

    def scratch(self, lines=None, title='[Scratch]', filetype=''):
        """Create a new scratch buffer with optional content."""
        _vim.command('enew')
        _vim.command('setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile')
        _vim.command('file %s' % _esc(title))
        if filetype:
            _vim.command('setlocal filetype=%s' % filetype)
        if lines:
            if isinstance(lines, str):
                lines = lines.split('\n')
            _vim.current.buffer[:] = [str(l) for l in lines]

    # -- Buffers info --

    def buffers(self):
        """List of open buffer names."""
        bufs = _vim.eval('getbufinfo({"buflisted": 1})')
        return [b['name'] for b in bufs if b['name']]

    # -- Pipe: chain commands ────────────────────────────────
    # Usage in .py:
    #   nf.pipe("GrepHere")           pipe STDOUT to another command
    #   nf.pipe("SortBuffer")         chain as many as you want
    #   nf.pipe_shell("sort | uniq")  pipe STDOUT through shell cmd

    _pipe_data = ''  # shared pipe buffer between commands

    def pipe(self, command_name):
        """
        Pipe current STDOUT to another NeoFinder command.
        The receiving command gets STDOUT content as STDIN.
        """
        # Store current STDOUT as pipe data
        _NeoFinder._pipe_data = STDOUT.text if 'STDOUT' in dir() else ''
        # Execute the target command
        _vim.command('NeoPythonExec %s' % command_name)

    def pipe_shell(self, cmd):
        """
        Pipe current STDOUT through a shell command.
        Returns the filtered output and replaces STDOUT.
        """
        input_text = STDOUT.text if 'STDOUT' in dir() else ''
        r = _subprocess.run(cmd, shell=True, capture_output=True,
                            text=True, input=input_text)
        return r.stdout


    # -- Echo --

    _echo_count = 0

    def echo(self, msg):
        """Echo a message in NeoFinder style."""
        _vim.command('echohl NeoFinderPrompt')
        _vim.command('echo "%s"' % _esc(str(msg)))
        _vim.command('echohl None')
        _NeoFinder._echo_count += 1

    def warn(self, msg):
        """Echo a warning message."""
        _vim.command('echohl WarningMsg')
        _vim.command('echo "%s"' % _esc(str(msg)))
        _vim.command('echohl None')
        _NeoFinder._echo_count += 1

    def error(self, msg):
        """Echo an error message."""
        _vim.command('echohl ErrorMsg')
        _vim.command('echo "%s"' % _esc(str(msg)))
        _vim.command('echohl None')
        _NeoFinder._echo_count += 1


nf = _NeoFinder()


# =========================================================================
#  STDIN / STDOUT / STDERR  -- standard I/O for commands
# =========================================================================
class _Stdin:
    """
    Standard input for a command.
    Populated by the handler "in" fields before execution.
    Also supports reading from the current buffer or asking the user.
    """

    def __init__(self):
        self._data = {}   # variables from handler "in"
        self._pipe = ''   # raw piped text (from buffer or previous command)

    def __getattr__(self, name):
        if name.startswith('_'):
            return object.__getattribute__(self, name)
        if name in self._data:
            return self._data[name]
        raise AttributeError("STDIN has no variable '%s' -- add it to the 'in' section of your .json handler" % name)

    def __contains__(self, name):
        return name in self._data

    @property
    def text(self):
        """Raw piped input as string (from buffer or chained command)."""
        return self._pipe

    @property
    def lines(self):
        """Piped input as list of lines."""
        return self._pipe.splitlines() if self._pipe else []

    def read_buffer(self):
        """Load current buffer content into stdin pipe."""
        self._pipe = '\n'.join(_vim.current.buffer)
        return self._pipe

    def set(self, name, value):
        self._data[name] = value


class _Stdout:
    """
    Standard output for a command.
    Collects output lines and flushes to an output buffer at the end.
    """

    def __init__(self):
        self._lines = []
        self._title = '[Output]'

    def write(self, *args):
        """Write lines. Accepts strings, lists, or multiple args."""
        for arg in args:
            if isinstance(arg, list):
                self._lines.extend(str(l) for l in arg)
            elif isinstance(arg, str):
                self._lines.extend(arg.splitlines())
            else:
                self._lines.append(str(arg))

    def print(self, *args, sep=' '):
        """Print-style output (like Python print)."""
        self._lines.append(sep.join(str(a) for a in args))

    def clear(self):
        self._lines = []

    @property
    def lines(self):
        return self._lines

    @property
    def text(self):
        return '\n'.join(self._lines)

    def flush(self):
        """Write collected output to a Vim scratch buffer."""
        if self._lines:
            nf.out.write(self._lines, self._title)


class _Stderr:
    """
    Standard error for a command.
    Collects errors/warnings. Shown after execution if non-empty.
    """

    def __init__(self):
        self._lines = []

    def write(self, *args):
        for arg in args:
            if isinstance(arg, list):
                self._lines.extend(str(l) for l in arg)
            elif isinstance(arg, str):
                self._lines.extend(arg.splitlines())
            else:
                self._lines.append(str(arg))

    def print(self, *args, sep=' '):
        self._lines.append(sep.join(str(a) for a in args))

    @property
    def lines(self):
        return self._lines

    @property
    def text(self):
        return '\n'.join(self._lines)

    def has_errors(self):
        return len(self._lines) > 0

    def show(self):
        """Display errors to the user."""
        if self._lines:
            for line in self._lines:
                nf.error(line)


# =========================================================================
#  TOML handler parser (reuse from toml_parser.py)
# =========================================================================
def _parse_handler_toml(path):
    """Parse a command .toml handler file."""
    # Import the toml parser that's already loaded or load it
    import importlib.util
    parser_path = _os.path.join(_os.path.dirname(_os.path.abspath(__file__
        if '__file__' in dir() else
        _vim.eval('substitute(expand("<sfile>:p:h"), "\\\\", "/", "g")') + '/runtime.py'
    )), 'toml_parser.py')

    # Direct simple parse since we already have one
    if not _os.path.isfile(path):
        return {}
    try:
        from toml_parser import parse_toml
        return parse_toml(path)
    except ImportError:
        pass

    # Inline mini parser as fallback
    result = {}
    section = result
    section_name = ''
    with open(path, 'r', encoding='utf-8') as f:
        for raw in f:
            line = raw.strip()
            if not line or line.startswith('#'):
                continue
            # Strip inline comments
            in_str = False
            for i, ch in enumerate(line):
                if ch == '"':
                    in_str = not in_str
                elif ch == '#' and not in_str:
                    line = line[:i].rstrip()
                    break
            # Section
            import re
            m = re.match(r'^\[([^\]]+)\]$', line)
            if m:
                section_name = m.group(1).strip()
                if section_name not in result:
                    result[section_name] = {}
                section = result[section_name]
                continue
            # Key = Value
            m = re.match(r'^(\w+)\s*=\s*(.+)$', line)
            if m:
                key, val = m.group(1), m.group(2).strip()
                if val == 'true': val = True
                elif val == 'false': val = False
                elif val.startswith('"') and val.endswith('"'): val = val[1:-1]
                elif val.startswith("'") and val.endswith("'"): val = val[1:-1]
                elif re.match(r'^-?\d+$', val): val = int(val)
                elif val.startswith('[') and val.endswith(']'):
                    inner = val[1:-1].strip()
                    if inner:
                        items = []
                        for item in inner.split(','):
                            item = item.strip().strip('"').strip("'")
                            items.append(item)
                        val = items
                    else:
                        val = []
                elif val.startswith('{') and val.endswith('}'):
                    # Inline table: { key = "val", key2 = "val2" }
                    inner = val[1:-1].strip()
                    obj = {}
                    # Split by comma, but respect quoted strings
                    parts = re.split(r',(?=(?:[^"]*"[^"]*")*[^"]*$)', inner)
                    for part in parts:
                        kv = re.match(r'\s*(\w+)\s*=\s*(.+)', part.strip())
                        if kv:
                            k = kv.group(1)
                            v = kv.group(2).strip()
                            if v == 'true': v = True
                            elif v == 'false': v = False
                            elif v.startswith('"') and v.endswith('"'): v = v[1:-1]
                            elif v.startswith("'") and v.endswith("'"): v = v[1:-1]
                            elif re.match(r'^-?\d+$', v): v = int(v)
                            elif v.startswith('[') and v.endswith(']'):
                                arr_inner = v[1:-1].strip()
                                if arr_inner:
                                    v = [i.strip().strip('"').strip("'") for i in arr_inner.split(',')]
                                else:
                                    v = []
                            obj[k] = v
                    val = obj
                section[key] = val
    return result


# =========================================================================
#  Handler: reads .toml contract, prepares scope, executes .py
# =========================================================================
def _interpolate(text, scope):
    """Replace ${var} placeholders with values from scope."""
    for var_name, value in scope.items():
        if isinstance(value, str):
            text = text.replace('${%s}' % var_name, value)
    return text


# =========================================================================
#  Pipeline engine -- chain steps like Airflow: a >> b >> c >> d
# =========================================================================
class _PipelineStep:
    """Represents a single step in a pipeline."""

    def __init__(self, name, step_type, value, on_fail='stop'):
        self.name = name
        self.type = step_type      # 'shell', 'command', 'python'
        self.value = value         # the cmd/command-name/code
        self.on_fail = on_fail     # 'stop', 'skip', 'continue'
        self.output = ''
        self.rc = 0
        self.error = ''
        self.status = 'pending'    # pending, running, success, failed, skipped


def _run_pipeline(handler, scope, stdout, stderr):
    """
    Execute a pipeline defined in [pipeline] section.

    TOML format:
        [pipeline]
        chain = "a >> b >> c"

        [pipeline.steps]
        a = { type = "shell", cmd = "lsof -i -nP" }
        b = { type = "shell", cmd = "grep LISTEN" }
        c = { type = "shell", cmd = "sort -t: -k2 -n" }

    Or simple shell-only chain:
        [pipeline]
        chain = "lsof -i -nP | grep LISTEN | sort"

    Each step receives previous step's STDOUT as STDIN.
    """
    pipeline = handler.get('pipeline', {})
    if not pipeline:
        return False  # no pipeline, use normal execution

    chain_str = pipeline.get('chain', '')
    steps_def = pipeline.get('steps', {})
    on_fail_default = pipeline.get('on_fail', 'stop')

    if not chain_str:
        return False

    # ── Parse chain ──────────────────────────────────────
    # Support two formats:
    #   1. Named steps: "a >> b >> c"
    #   2. Shell pipe:  "cmd1 | cmd2 | cmd3"

    if '>>' in chain_str:
        # Named steps mode
        step_names = [s.strip() for s in chain_str.split('>>')]
        steps = []
        for sname in step_names:
            if sname in steps_def:
                sdef = steps_def[sname]
                if isinstance(sdef, dict):
                    stype = sdef.get('type', 'shell')
                    cmd = sdef.get('cmd', sdef.get('command', sdef.get('code', '')))
                    fail = sdef.get('on_fail', on_fail_default)
                else:
                    stype = 'shell'
                    cmd = str(sdef)
                    fail = on_fail_default
                steps.append(_PipelineStep(sname, stype, cmd, fail))
            else:
                # Assume it's a NeoFinder command name
                steps.append(_PipelineStep(sname, 'command', sname, on_fail_default))
    else:
        # Simple shell pipe: "cmd1 | cmd2 | cmd3"
        parts = [p.strip() for p in chain_str.split('|')]
        steps = [_PipelineStep('step_%d' % i, 'shell', cmd, on_fail_default)
                 for i, cmd in enumerate(parts)]

    if not steps:
        return False

    # ── Print pipeline header ────────────────────────────
    total = len(steps)
    stdout.print("  PIPELINE  %s" % chain_str)
    stdout.print("  " + "═" * 70)
    stdout.print("")

    # ── Execute chain ────────────────────────────────────
    pipe_data = ''  # flowing data between steps

    # If STDIN has data (from pipe="buffer" or previous command), use it
    if scope.get('STDIN') and scope['STDIN'].text:
        pipe_data = scope['STDIN'].text

    for i, step in enumerate(steps):
        step.status = 'running'
        step_label = "[%d/%d] %s" % (i + 1, total, step.name)

        # Interpolate variables in command
        cmd = _interpolate(step.value, scope)

        try:
            if step.type == 'shell':
                r = _subprocess.run(
                    cmd, shell=True, capture_output=True, text=True,
                    input=pipe_data if pipe_data else None
                )
                step.output = r.stdout
                step.error = r.stderr
                step.rc = r.returncode

            elif step.type == 'command':
                # Run a NeoFinder command -- store output, pass pipe
                nf._pipe_data = pipe_data
                _vim.command('NeoPythonExec %s' % cmd)
                step.output = nf._pipe_data or ''
                step.rc = 0

            elif step.type == 'python':
                # Inline python expression
                local_scope = dict(scope)
                local_scope['PIPE'] = pipe_data
                local_scope['PIPE_LINES'] = pipe_data.splitlines() if pipe_data else []
                exec(cmd, local_scope)
                step.output = local_scope.get('RESULT', pipe_data)
                if isinstance(step.output, list):
                    step.output = '\n'.join(str(l) for l in step.output)
                step.rc = 0

        except Exception as e:
            step.error = str(e)
            step.rc = 1

        # ── Evaluate result ──────────────────────────────
        if step.rc == 0 or step.output:
            step.status = 'success'
            pipe_data = step.output  # pass to next step
            stdout.print("  %s  ✓  %s" % (step_label, _truncate(cmd, 50)))
        else:
            step.status = 'failed'
            stdout.print("  %s  ✗  %s" % (step_label, _truncate(cmd, 50)))
            if step.error:
                stdout.print("       error: %s" % step.error.strip()[:80])

            if step.on_fail == 'stop':
                stdout.print("")
                stdout.print("  ⚠ Pipeline stopped at step %d" % (i + 1))
                stderr.print("Pipeline failed at: %s" % step.name)
                break
            elif step.on_fail == 'skip':
                step.status = 'skipped'
                # Don't update pipe_data, next step gets previous output
                continue

    # ── Final output ─────────────────────────────────────
    stdout.print("")
    stdout.print("  " + "─" * 70)

    # Summary
    success = sum(1 for s in steps if s.status == 'success')
    failed = sum(1 for s in steps if s.status == 'failed')
    skipped = sum(1 for s in steps if s.status == 'skipped')
    stdout.print("  Done: %d/%d ok  %d failed  %d skipped" % (success, total, failed, skipped))
    stdout.print("  " + "─" * 70)
    stdout.print("")

    # Print final pipe output
    if pipe_data:
        stdout.print("  OUTPUT:")
        stdout.print("  " + "─" * 70)
        for line in pipe_data.strip().splitlines():
            stdout.print("  %s" % line)

    return True  # pipeline was executed


def _truncate(s, maxlen):
    return s if len(s) <= maxlen else s[:maxlen - 3] + '...'


def _run_command(py_path):
    """
    Main entry point called by python.vim.

    Flow:
      1. Read .toml handler (contract)
      2. Validate prerequisites ([validate])
      3. Evaluate environment variables ([env])
      4. Process [in] -> populate STDIN + scope variables
      5. Process pipe -> load buffer into STDIN if requested
      6. Auto-print header ([header])
      7. Shell-only mode ([shell]) or execute .py
      8. Post-execution error handling ([error])
      9. Flush STDOUT to output buffer
      10. Show STDERR if any errors
    """
    toml_path = py_path.rsplit('.', 1)[0] + '.toml'
    handler = {}

    # ── 1) Read handler ──────────────────────────────────────
    if _os.path.isfile(toml_path):
        try:
            handler = _parse_handler_toml(toml_path)
        except Exception as e:
            nf.error("Bad TOML in: %s (%s)" % (toml_path, e))
            return

    # ── 2) Platform check ────────────────────────────────────
    platform_str = handler.get('platform', '')
    if platform_str:
        import platform
        current = platform.system().lower()
        allowed = [p.strip().lower() for p in platform_str.split(',')]
        if current not in allowed:
            nf.warn("Command not available on %s (requires: %s)" % (current, platform_str))
            return

    # ── 3) Validate prerequisites ────────────────────────────
    validate = handler.get('validate', {})
    if validate:
        # Check required binaries
        cmds = validate.get('commands', [])
        if isinstance(cmds, str):
            cmds = [cmds]
        import shutil
        for cmd in cmds:
            if not shutil.which(cmd):
                nf.error("Required command not found: %s" % cmd)
                return

        # Check filetype restriction
        ft_allowed = validate.get('filetype', [])
        if isinstance(ft_allowed, str):
            ft_allowed = [ft_allowed]
        if ft_allowed:
            current_ft = _vim.eval('&filetype')
            if current_ft not in ft_allowed:
                nf.error("Command requires filetype: %s (current: %s)" % (', '.join(ft_allowed), current_ft or 'none'))
                return

        # Check minimum buffer lines
        min_lines = validate.get('min_lines', 0)
        if min_lines and int(min_lines) > 0:
            buf_len = len(_vim.current.buffer)
            if buf_len < int(min_lines):
                nf.error("Buffer needs at least %s lines (has %d)" % (min_lines, buf_len))
                return

    # ── 4) Create I/O streams ────────────────────────────────
    stdin  = _Stdin()
    stdout = _Stdout()
    stderr = _Stderr()

    out_title = handler.get('out', '')

    # ── 5) Evaluate [env] -> auto-injected variables ─────────
    scope = {'nf': nf, 'STDIN': stdin, 'STDOUT': stdout, 'STDERR': stderr}
    env = handler.get('env', {})
    if env:
        import platform as _platform
        import datetime as _datetime
        env_scope = {
            'nf': nf, 'platform': _platform,
            'datetime': _datetime.datetime, 'date': _datetime.date,
            'timedelta': _datetime.timedelta,
            'os': _os, 'subprocess': _subprocess,
        }
        for var_name, expr in env.items():
            try:
                scope[var_name] = eval(str(expr), env_scope)
            except Exception as e:
                scope[var_name] = str(expr)

    # ── 6) Process [in] -> ask user, populate STDIN + scope ──
    inputs = handler.get('in', {})
    for var_name, spec in inputs.items():
        _vim.command('redraw')

        if isinstance(spec, dict):
            # Rich input: { prompt, default, options, type }
            prompt = spec.get('prompt', var_name + ': ')
            default = spec.get('default', '')
            options = spec.get('options', [])
            input_type = spec.get('type', 'string')

            if input_type == 'confirm':
                result = nf.confirm(prompt)
                value = 'yes' if result == 1 else 'no'
            elif options:
                # Show numbered list and let user pick
                selected = nf.select(options, str(prompt))
                if selected is None:
                    if default:
                        value = str(default)
                    else:
                        return
                else:
                    value = selected
            elif input_type == 'file':
                _vim.command("let s:_nf_input = input('%s', '', 'file')" % _esc(str(prompt)))
                value = _vim.eval('s:_nf_input')
            else:
                if default:
                    _vim.command("let s:_nf_input = input('%s', '%s')" % (_esc(str(prompt)), _esc(str(default))))
                    value = _vim.eval('s:_nf_input')
                else:
                    value = nf.input(str(prompt))
        else:
            # Simple string prompt (backwards compatible)
            value = nf.input(str(spec))

        _vim.command('redraw')
        if not value and not (isinstance(spec, dict) and spec.get('type') == 'confirm'):
            return  # user cancelled
        stdin.set(var_name, value)
        scope[var_name] = value

    # ── 7) Process "pipe" -> load buffer or piped data into STDIN
    pipe_val = handler.get('pipe', '')
    if pipe_val == 'buffer':
        stdin.read_buffer()
    elif nf._pipe_data:
        # Receiving piped data from a previous command
        stdin._pipe = nf._pipe_data
        nf._pipe_data = ''  # consume it

    # ── 8) Interpolate ${var} in output title ────────────────
    if out_title:
        out_title = _interpolate(out_title, scope)
        stdout._title = out_title

    # ── 9) Auto-print header ─────────────────────────────────
    header = handler.get('header', {})
    if header and header.get('show', False):
        sep = str(header.get('separator', '='))
        width = int(header.get('width', 50))
        cmd_name = handler.get('name', '')
        stdout.print(cmd_name)
        stdout.print(sep * width)
        # Print listed input vars in header
        info_vars = header.get('info', [])
        if isinstance(info_vars, str):
            info_vars = [info_vars]
        for v in info_vars:
            if v in scope and isinstance(scope[v], str):
                stdout.print("  %s: %s" % (v, scope[v]))
        if info_vars:
            stdout.print(sep * width)
        stdout.print('')

    # ── 10) Execute: pipeline, shell-only, or .py ──────────
    nf._echo_count = 0

    # Check for pipeline first
    if handler.get('pipeline', {}):
        if _run_pipeline(handler, scope, stdout, stderr):
            # Pipeline handled everything
            out_filetype = handler.get('filetype', '')
            silent = handler.get('silent', False)
            if not silent:
                stdout.flush()
                if out_filetype and stdout.lines:
                    _vim.command('setlocal filetype=%s' % out_filetype)
            stderr.show()
            return

    timeout = int(handler.get('timeout', 0))
    shell_section = handler.get('shell', {})
    shell_cmd = shell_section.get('cmd', '') if isinstance(shell_section, dict) else ''

    if shell_cmd and not _os.path.isfile(py_path):
        # Shell-only mode: run cmd from TOML, no .py needed
        shell_cmd = _interpolate(shell_cmd, scope)
        try:
            if timeout > 0:
                r = _subprocess.run(shell_cmd, shell=True, capture_output=True,
                                    text=True, timeout=timeout)
            else:
                r = _subprocess.run(shell_cmd, shell=True, capture_output=True, text=True)
            if r.stdout:
                stdout.write(r.stdout.splitlines())
            if r.returncode != 0 and r.stderr:
                error_section = handler.get('error', {})
                fail_msg = error_section.get('fail', '')
                if fail_msg:
                    stderr.print(fail_msg)
                else:
                    stderr.write(r.stderr.splitlines())
        except _subprocess.TimeoutExpired:
            stderr.print("Command timed out after %ds" % timeout)
        except Exception as e:
            stderr.print("Shell error: %s" % str(e))
    elif _os.path.isfile(py_path):
        # Execute .py script
        with open(py_path, 'r') as f:
            code = f.read()
        try:
            if timeout > 0:
                # For .py scripts, timeout via signal (unix only)
                import signal
                def _timeout_handler(signum, frame):
                    raise TimeoutError("Script timed out after %ds" % timeout)
                old_handler = signal.signal(signal.SIGALRM, _timeout_handler)
                signal.alarm(timeout)
                try:
                    exec(code, scope)
                finally:
                    signal.alarm(0)
                    signal.signal(signal.SIGALRM, old_handler)
            else:
                exec(code, scope)
        except TimeoutError as e:
            stderr.print(str(e))
        except Exception as e:
            stderr.write("Error: %s" % str(e))

    # ── 11) Post-execution error checks ──────────────────────
    error_section = handler.get('error', {})
    if error_section:
        if not stdout.lines and error_section.get('empty', ''):
            stderr.print(error_section['empty'])

    # ── 12) Set output buffer filetype ───────────────────────
    out_filetype = handler.get('filetype', '')

    # ── 13) Flush STDOUT to output buffer ────────────────────
    silent = handler.get('silent', False)
    if not silent:
        stdout.flush()
        # Apply filetype after buffer is created
        if out_filetype and stdout.lines:
            _vim.command('setlocal filetype=%s' % out_filetype)

    # ── 14) Show STDERR ──────────────────────────────────────
    stderr.show()

    # ── 15) Pipe to next command if pipe_to defined ──────────
    pipe_to = handler.get('pipe_to', '')
    pipe_shell = handler.get('pipe_shell', '')
    if stdout.lines and pipe_to:
        # Chain: send STDOUT to another NeoFinder command as STDIN
        nf._pipe_data = stdout.text
        _vim.command('NeoPythonExec %s' % pipe_to)
    elif stdout.lines and pipe_shell:
        # Filter: pipe STDOUT through a shell command
        shell_cmd = _interpolate(pipe_shell, scope)
        r = _subprocess.run(shell_cmd, shell=True, capture_output=True,
                            text=True, input=stdout.text)
        if r.stdout:
            stdout.clear()
            stdout.write(r.stdout.splitlines())
            stdout.flush()

    # ── 16) Pause for echo-only commands ─────────────────────
    if nf._echo_count > 0 and not stdout.lines:
        _vim.eval('input(" ")')
