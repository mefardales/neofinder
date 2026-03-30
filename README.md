# NeoFinder - Matrix Edition

A modern fuzzy finder and sysadmin/hacker toolkit for Vim.
100% pure Vimscript. Zero external dependencies. Built for remote servers.

```
  _   _            _____ _           _
 | \ | | ___  ___ |  ___(_)_ __   __| | ___ _ __
 |  \| |/ _ \/ _ \| |_  | | '_ \ / _` |/ _ \ '__|
 | |\  |  __/ (_) |  _| | | | | | (_| |  __/ |
 |_| \_|\___|\___/|_|   |_|_| |_|\__,_|\___|_|
                                  Matrix Edition
```

## Features

- **Command palette** (`:Neo`) -- fuzzy search all actions, themes, sources
- **Global themes** -- Matrix, Dark, Cyberpunk affect the entire editor + statusline
- **Powerline statusline** -- mode, git branch, buffer count, clock
- **Sysadmin sources** -- configs, logs, systemd, journalctl, SSH hosts, Ansible
- **Buffer & tab groups** -- tmux-like named groups, terminal integration
- **Persistent tagging** -- bookmark files across sessions
- **Python commands** -- register custom scripts, bind to keys
- **Resizable preview** -- Left/Right arrows resize pane live
- **Multi-select** -- batch open, sudoedit, tail, restart, ssh
- **Auto backend** -- ripgrep > fd > find (graceful fallback)
- **Works everywhere** -- Vim 7.4+, Vim 8+, Neovim

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

## Commands

| Command | Description | Mapping |
|---|---|---|
| `:Neo` | **Command palette** (search everything) | `<Leader>fp` |
| `:Nf` | Fuzzy file finder | `<Leader>ff` |
| `:Nc` | Config files (/etc, ~/.config) | `<Leader>fc` |
| `:Nl` | Log browser (/var/log) | `<Leader>fl` |
| `:Ns` | systemd services + actions | `<Leader>fs` |
| `:Nj` | journalctl search | `<Leader>fj` |
| `:Nh` | SSH hosts | `<Leader>fh` |
| `:Na` | Ansible playbooks & roles | `<Leader>fa` |
| `:Nk` | Personal scripts (~/bin, etc.) | `<Leader>fk` |
| `:Nw` | Wordlists (seclists, dirb) | `<Leader>fw` |
| `:Nx` | Exploits (exploitdb, msf) | `<Leader>fx` |
| `:Nt` | Tagged/bookmarked files | `<Leader>ft` |
| `:Nb` | Buffer list | `<Leader>fb` |
| `:Ng` | Tab groups (tmux-like) | `<Leader>fg` |
| `:Nr` | Open terminal | `<Leader>fR` |

## Finder Keybindings

| Key | Action |
|---|---|
| `Up` / `Down` | Navigate items |
| `<CR>` | Open / execute |
| `<C-v>` | Vertical split |
| `<C-x>` | Horizontal split |
| `<C-s>` | sudoedit |
| `<C-t>` | tail -f (logs) |
| `<C-r>` | systemctl restart |
| `<C-h>` | ssh connect (hosts) |
| `Left` / `Right` | Resize preview pane |
| `<Tab>` | Toggle multi-select |
| `<C-a>` | Select all |
| `<C-d>` | Deselect / delete buffer |
| `Backspace` | Back to palette (empty query) |
| `<F1>` | Settings panel |
| `<Esc>` | Close |

## Themes

Themes affect the **entire editor** -- Normal, StatusLine, syntax groups, etc.

| Theme | Description |
|---|---|
| `matrix` | Green on black (default) |
| `dark` | Subtle gray/white on dark |
| `cyberpunk` | Magenta/cyan neon |
| `default` | Vim's native colors |

Switch themes via the palette (`:Neo` then type "theme") or `:NeoConfig`.

### Custom themes

```bash
# Create from the palette or manually:
mkdir -p ~/.neofinder/themes/
```

Custom theme files are simple Vimscript dictionaries in `~/.neofinder/themes/<name>.vim`.

## Python Commands

When Vim has `+python3`:

```vim
" Register inline
call neofinder#python#register('BackupNginx', '
    import os
    os.system("cp -r /etc/nginx ~/backup/")
    nf.echo("Backup complete!")
')

" Register from file
call neofinder#python#register_file('Deploy', '~/scripts/deploy.py')

" Bind to key
call neofinder#python#bind('BackupNginx', '<leader>b')
```

Auto-loads `.py` and `.vim` files from `~/.neofinder/python/` on startup.

## Configuration

```vim
let g:neofinder = {
    \ 'theme':        'matrix',
    \ 'statusline':   1,
    \ 'preview':      1,
    \ 'preview_width': 60,
    \ 'height':       15,
    \ 'max_files':    50000,
    \ 'no_mappings':  0,
    \ 'ignore':       ['/proc', '/sys', '/dev', '.git', 'node_modules'],
    \ 'config_paths': ['/etc', '~/.config'],
    \ 'log_paths':    ['/var/log'],
    \ }
```

## Project Structure

```
neofinder/
├── plugin/neofinder.vim          # Commands, config, mappings
├── autoload/neofinder.vim        # Entry point, palette, backend detection
├── autoload/neofinder/
│   ├── core.vim                  # Fuzzy engine, UI, input loop, nav stack
│   ├── theme.vim                 # Global multi-theme system (editor+finder+statusline)
│   ├── preview.vim               # Syntax-highlighted preview with resize
│   ├── config.vim                # Settings panel (themes, paths, toggles)
│   ├── statusline.vim            # Powerline-style global statusline
│   ├── buffers.vim               # Buffer manager, tab groups, terminal
│   ├── python.vim                # Custom Python commands system
│   ├── tags.vim                  # Persistent tagging/bookmarks
│   ├── sources.vim               # Data gathering for all sources
│   └── actions.vim               # Contextual actions (sudo, ssh, tail, etc.)
├── doc/neofinder.txt             # Vim help file
├── install.sh                    # One-click installer
└── README.md
```

## License

MIT
