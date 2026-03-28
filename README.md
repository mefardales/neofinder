# NeoFinder - Matrix Edition

A modern, powerful fuzzy finder and sysadmin/hacker toolkit for Vim.
100% pure Vimscript. Zero external dependencies. Replaces and greatly extends ctrlp.vim.

```
  _   _            _____ _           _
 | \ | | ___  ___ |  ___(_)_ __   __| | ___ _ __
 |  \| |/ _ \/ _ \| |_  | | '_ \ / _` |/ _ \ '__|
 | |\  |  __/ (_) |  _| | | | | | (_| |  __/ |
 |_| \_|\___|\___/|_|   |_|_| |_|\__,_|\___|_|
                                  Matrix Edition
```

## Features

- **Fuzzy file finder** with scoring, word-boundary bonuses, and instant filtering
- **Matrix cyberpunk theme** -- green on black, full syntax highlighting in preview
- **Sysadmin sources** -- configs, logs, systemd services, journalctl, SSH hosts, Ansible
- **Persistent tagging** -- bookmark files across sessions (`~/.neofinder/tags`)
- **Multi-select** -- batch open, sudoedit, tail, restart, ssh
- **Auto backend detection** -- ripgrep > fd > find (graceful fallback)
- **Preview window** with filetype detection (shebang, extension, content heuristics)
- **Works everywhere** -- Vim 7.4+, Vim 8+, Neovim

## Installation

### vim-plug

```vim
Plug 'yourusername/neofinder'
```

### Vim 8+ native packages

```bash
git clone https://github.com/yourusername/neofinder.git \
    ~/.vim/pack/plugins/start/neofinder
vim -c 'helptags ~/.vim/pack/plugins/start/neofinder/doc' -c q
```

### Neovim

```bash
git clone https://github.com/yourusername/neofinder.git \
    ~/.local/share/nvim/site/pack/plugins/start/neofinder
```

### One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/neofinder/main/install.sh | bash
```

## Commands

| Command | Description | Mapping |
|---|---|---|
| `:NeoFinder` | Fuzzy file finder (cwd) | `<Leader>ff` |
| `:NeoConfigs` | Config files (/etc, ~/.config) | `<Leader>fc` |
| `:NeoLogs` | /var/log browser | `<Leader>fl` |
| `:NeoServices` | systemd units + actions | `<Leader>fs` |
| `:NeoJournal` | journalctl search | `<Leader>fj` |
| `:NeoHosts` | SSH hosts | `<Leader>fh` |
| `:NeoAnsible` | Playbooks & roles | `<Leader>fa` |
| `:NeoTags` | Tagged/bookmarked files | `<Leader>ft` |
| `:NeoTag` | Tag current file | `<Leader>fT` |
| `:NeoUntag` | Untag current file | |
| `:NeoHelp` | Command reference | `<Leader>f?` |

## Finder Keybindings

| Key | Action |
|---|---|
| `<CR>` | Open / execute |
| `<C-v>` | Open in vertical split |
| `<C-x>` | Open in horizontal split |
| `<C-s>` | sudoedit |
| `<C-t>` | tail -f (logs) |
| `<C-r>` | systemctl restart (services) |
| `<C-h>` | ssh (hosts) |
| `<Tab>` | Toggle multi-select |
| `<C-a>` | Select all |
| `<C-d>` | Deselect all |
| `<C-j>`/`<C-n>` | Next item |
| `<C-k>`/`<C-p>` | Previous item |
| `<Esc>`/`<C-c>` | Close |

## Configuration

```vim
let g:neofinder = {
    \ 'theme':        'matrix',
    \ 'preview':      1,
    \ 'preview_width': 60,
    \ 'height':       15,
    \ 'max_files':    50000,
    \ 'no_mappings':  0,
    \ 'ignore':       ['/proc', '/sys', '/dev', '.git', 'node_modules'],
    \ 'tag_file':     '~/.neofinder/tags',
    \ 'config_paths': ['/etc', '~/.config'],
    \ 'log_paths':    ['/var/log'],
    \ }
```

## Backend Detection

NeoFinder auto-detects the fastest available backend:

1. **ripgrep** (`rg`) -- fastest, respects .gitignore
2. **fd** -- fast, respects .gitignore
3. **find** -- universal fallback, always available

## Project Structure

```
neofinder/
├── plugin/neofinder.vim          # Commands, config defaults, mappings
├── autoload/neofinder.vim        # Main entry, backend detection
├── autoload/neofinder/
│   ├── core.vim                  # Fuzzy engine, buffer UI, input loop
│   ├── theme.vim                 # Matrix cyberpunk color scheme
│   ├── preview.vim               # Syntax-highlighted preview window
│   ├── tags.vim                  # Persistent tagging system
│   ├── sources.vim               # Data gathering for all source types
│   └── actions.vim               # Contextual actions (edit, sudo, ssh, etc.)
├── doc/neofinder.txt             # Vim help file
├── install.sh                    # One-click installer
└── README.md
```

## License

MIT
