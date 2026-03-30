# NeoFinder

A modern file browser, command runner, and editor toolkit for Vim.
Pure Vimscript core + Python commands. Works on Linux, macOS, Windows.

```
  _   _            _____ _           _
 | \ | | ___  ___ |  ___(_)_ __   __| | ___ _ __
 |  \| |/ _ \/ _ \| |_  | | '_ \ / _` |/ _ \ '__|
 | |\  |  __/ (_) |  _| | | | | | (_| |  __/ |
 |_| \_|\___|\___/|_|   |_|_| |_|\__,_|\___|_|


```

## Features

- **File browser** with fuzzy search, glob patterns (`*.py`, `**/*.vim`), and Python-powered background indexing
- **Command system** -- every command is a `.py` file + `.toml` handler. STDIN/STDOUT/STDERR standard I/O
- **Tag groups** -- bookmark files into named groups, browse by group
- **TOML configuration** -- `~/.neofinder/config.toml` with comments, auto-reload on save
- **Global themes** -- Matrix, Dark, Cyberpunk affect the entire editor + statusline
- **Powerline statusline** -- mode, git branch, buffer count, filetype, clock
- **Window management** -- split, resize, navigate with keyboard shortcuts
- **Buffer navigation** -- switch buffers without leaving the editor
- **Works everywhere** -- Vim 8+, Neovim, Windows, Linux, macOS

## Installation

### vim-plug

```vim
Plug 'mefardales/neofinder'
```

### Vim 8+ native packages

```bash
git clone https://github.com/mefardales/neofinder.git \
    ~/.vim/pack/plugins/start/neofinder
```

### Neovim

```bash
git clone https://github.com/mefardales/neofinder.git \
    ~/.local/share/nvim/site/pack/plugins/start/neofinder
```

### One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/mefardales/neofinder/main/install.sh | bash
```

## Palette

Open with `:Neo` or `<Leader>fp`. Everything starts here:

```
Browse          :ff   file browser
Buffers         :fb   open buffers  C-Left/Right
Tags            :fg   tagged file groups
Terminal        :fR   open terminal
Run             :fr   execute commands
Commands        :fe   edit/create commands
Config          :fc   config.toml
```

## Keybindings

### Palette & Navigation

| Key | Action |
|---|---|
| `<Leader>fp` | Open palette |
| `<Leader>ff` | File browser |
| `<Leader>fb` | Buffer list |
| `<Leader>fg` | Tag groups |
| `<Leader>ft` | Tag current file |
| `<Leader>fu` | Untag current file |
| `<Leader>fR` | Open terminal |
| `<Leader>fr` | Run commands |
| `<Leader>fe` | Edit/create commands |
| `<Leader>fc` | Open config.toml |

### Inside the Finder

| Key | Action |
|---|---|
| `Up` / `Down` | Navigate items |
| `Enter` | Open file / enter directory |
| `Backspace` | Go up (browse) / back to palette |
| `Ctrl-V` | Open in vertical split |
| `Ctrl-X` | Open in horizontal split |
| `Ctrl-T` | Tag file under cursor to a group |
| `Ctrl-B` | Switch to buffer list |
| `Tab` | Toggle focus: finder <-> editor |
| `Ctrl-Space` | Toggle multi-select |
| `Ctrl-A` | Select all |
| `Left` / `Right` | Resize preview pane |
| `PageUp` / `PageDown` | Resize finder panel |
| `Esc` | Close |

### Search Modes

Type in the finder to filter:

| Query | Mode | Example |
|---|---|---|
| `main` | Fuzzy | matches m-a-i-n anywhere |
| `*.py` | Glob | only `.py` files |
| `*.json` | Glob | only `.json` files |
| `test_*` | Glob | files starting with `test_` |
| `**/*.vim` | Glob | `.vim` files in any subdirectory |

### Window Management

| Key | Action |
|---|---|
| `<Leader>sv` | Vertical split |
| `<Leader>sh` | Horizontal split |
| `<Leader>sc` | Close window |
| `Shift+Tab` | Cycle between windows |
| `Shift+Left/Right` | Resize window horizontally |
| `Shift+Up/Down` | Resize window vertically |
| `Ctrl+Arrow` | Resize (alternative) |

### Buffer Navigation

| Key | Action |
|---|---|
| `<Leader>bn` | Next buffer |
| `<Leader>bp` | Previous buffer |
| `<Leader>fb` | Buffer list in finder |

## Themes

Themes affect the **entire editor** -- Normal, StatusLine, syntax groups, etc.

| Theme | Description |
|---|---|
| `matrix` | Green on black (default) |
| `dark` | Subtle gray/white on dark |
| `cyberpunk` | Magenta/cyan neon |
| `default` | Vim's native colors |

Switch themes by editing `config.toml` (`<Leader>fc`).

## Configuration

All settings live in `~/.neofinder/config.toml`. Open with `<Leader>fc`. Changes apply instantly on save (`:w`).

```toml
# Theme: "matrix", "dark", "cyberpunk", "default"
[theme]
name = "matrix"

# Finder panel
[finder]
height = 15
preview = true
preview_width = 60
max_files = 50000

# Editor defaults
[editor]
line_numbers = false
wrap = true
tabstop = 4
expandtab = true
encoding = "utf-8"
mouse = "a"
clipboard = "unnamedplus"
splitright = true
splitbelow = true
undofile = true

# Search
[search]
ignorecase = true
smartcase = true
hlsearch = true

# Auto-actions on save
[on_save]
trim_whitespace = true
final_newline = true

# Ignore patterns for file browser
ignore = [".git", "node_modules", "__pycache__"]

# Paths
[paths]
tags = "~/.neofinder/tags"
commands = "~/.neofinder/python"

# Keybindings
[keybindings]
enabled = true
```

## Command System

Every command is two files: a `.toml` handler (contract) and a `.py` file (logic).

### Create a command

1. Open palette > `Commands :fe` > `[+] New command`
2. Enter name (e.g. `DiskUsage`)
3. Edit the `.toml` handler and `.py` logic in vsplit

Or manually create files in `~/.neofinder/python/`:

### Handler (.toml)

```toml
# ══════════════════════════════════════════════
# DiskUsage -- check disk space
# ══════════════════════════════════════════════

name = "DiskUsage"
desc = "Show disk usage"
deps = ["output", "shell"]
out = "[Disk Usage]"
```

### Logic (.py)

```python
nf.sh_output("df -h")
```

### Handler with input

```toml
name = "NetScan"
desc = "Port scan a host"
deps = ["input", "output", "shell"]
out = "[Scan ${host}]"

[in]
host = "Host/IP: "
```

The `[in]` section asks the user for variables before execution. Each key becomes a variable in your `.py`:

```python
# 'host' is already available as a variable
STDOUT.print("Scanning %s..." % host)
result = nf.sh_lines("ping -c 3 %s" % host)
STDOUT.write(result)
```

### Standard I/O

Every command gets three streams injected:

| Stream | Usage | Destination |
|---|---|---|
| `STDIN` | `.text`, `.lines`, `.varname` | Input from handler `[in]` or pipe |
| `STDOUT` | `.print()`, `.write()` | Auto-flushed to output buffer |
| `STDERR` | `.print()`, `.write()` | Auto-shown as errors after execution |

### Python API (`nf.*`)

| Category | Methods |
|---|---|
| **Context** | `nf.file`, `nf.dir`, `nf.line`, `nf.filetype`, `nf.theme` |
| **Buffer** | `nf.buf.lines`, `nf.buf.text`, `nf.buf.write(x)`, `nf.buf.append(x)`, `nf.buf.clear()` |
| **Shell** | `nf.sh(cmd)` -> `(stdout, stderr, rc)`, `nf.sh_output(cmd)`, `nf.sh_lines(cmd)` |
| **Input** | `nf.input(prompt)`, `nf.confirm(msg)`, `nf.select(items)` |
| **Tags** | `nf.tags.groups()`, `nf.tags.files(group)`, `nf.tags.add(path, group)` |
| **Files** | `nf.open(p)`, `nf.vsplit(p)`, `nf.split(p)`, `nf.scratch(lines, title)` |
| **Messages** | `nf.echo(x)`, `nf.warn(x)`, `nf.error(x)` |

### Handler fields

| Field | Type | Description |
|---|---|---|
| `name` | string | Command name (PascalCase) |
| `desc` | string | Description shown in palette |
| `deps` | array | Dependencies: `"input"`, `"output"`, `"shell"`, `"buffer"`, `"tags"` |
| `out` | string | Output buffer title. Supports `${var}` interpolation |
| `pipe` | string | `"buffer"` to load current buffer into `STDIN` |
| `[in]` | section | Variables to ask the user. `key = "prompt"` |

### Built-in commands

| Command | Description |
|---|---|
| `HelloWorld` | System check |
| `HelloDemo` | Full API reference |
| `RunHere` | Run any shell command |
| `GitLog` | Recent git commits |
| `GrepHere` | Grep pattern in cwd |
| `SortBuffer` | Sort current buffer lines |
| `TaggedFiles` | Browse tags by group |
| `NetInfo` | Network interfaces, routes, DNS, ports |
| `NetScan` | Ping + DNS + port scan a host |
| `NetConns` | Active network connections |

## Tag System

Tag files into named groups for quick access.

| Key | Action |
|---|---|
| `<Leader>ft` | Tag current file (asks for group) |
| `<Leader>fu` | Untag current file |
| `<Leader>fg` | Browse tag groups |
| `Ctrl-T` | Tag file under cursor (inside finder) |
| `Ctrl-D` | Untag file under cursor (inside tag list) |

Tags are stored in `~/.neofinder/tags`:

```
servers:/etc/nginx/nginx.conf
dotfiles:/home/user/.bashrc
default:/var/log/syslog
```

## Project Structure

```
neofinder/
├── plugin/neofinder.vim              # Commands, mappings, startup
├── autoload/neofinder.vim            # Palette, browse, backend detection
├── autoload/neofinder/
│   ├── core.vim                      # Finder UI, input loop, fuzzy/glob filter
│   ├── theme.vim                     # Global themes (editor + finder + statusline)
│   ├── preview.vim                   # File preview pane
│   ├── config.vim                    # TOML config loader + auto-reload
│   ├── statusline.vim                # Powerline statusline
│   ├── buffers.vim                   # Buffer manager, terminal
│   ├── python.vim                    # Command system (.py + .toml)
│   ├── tags.vim                      # Tag groups (persistent bookmarks)
│   ├── sources.vim                   # Data gathering for all sources
│   ├── actions.vim                   # Open, split, tag, execute actions
│   ├── indexer.vim                   # Vim wrapper for Python indexer
│   ├── indexer.py                    # Fast file indexer (os.walk)
│   ├── runtime.py                    # Python runtime (nf.*, STDIN/STDOUT/STDERR)
│   ├── toml_parser.py                # TOML parser for config + handlers
│   └── commands/                     # Built-in commands
│       ├── hello_world.toml + .py
│       ├── hello_demo.toml + .py
│       ├── run_here.toml + .py
│       ├── git_log.toml + .py
│       ├── grep_here.toml + .py
│       ├── sort_buffer.toml + .py
│       ├── tagged_files.toml + .py
│       ├── net_info.toml + .py
│       ├── net_scan.toml + .py
│       └── net_conns.toml + .py
├── install.sh
└── README.md
```

## License

MIT
