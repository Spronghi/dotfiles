# dotfiles

Keep the ball rolling.

Personal configs for a macOS (and occasionally WSL) dev setup built around **WezTerm + Neovim + zsh**, with tiling via AeroSpace and Claude Code integration baked into the terminal.

## What's inside

| Path | What it configures |
|------|-------------------|
| `wezterm/` | WezTerm: keys, theme, workspaces, sessionizer, Claude Code status bar |
| `nvim/` | Neovim (lazy.nvim, lsp-zero, telescope, which-key, …) |
| `.zshrc` | zsh + oh-my-zsh, starship, zoxide, fzf, atuin, nvm, bun |
| `.aerospace.toml` | AeroSpace tiling window manager |
| `atuin/` | Atuin shell history |
| `starship.toml` | Starship prompt |
| `claude/` | Claude Code hook that feeds session status to WezTerm |
| `.wslconfig` | WSL memory/CPU limits (Windows only) |

## Tools

- [wezterm](https://wezfurlong.org/wezterm/index.html) — terminal
- [nvim](https://neovim.io/) — editor
- [cascadia mono](https://github.com/microsoft/cascadia-code) — font
- [oh-my-zsh](https://ohmyz.sh/#install) — zsh framework
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [zsh-npm-scripts-autocomplete](https://github.com/grigorii-zander/zsh-npm-scripts-autocomplete)
- [starship](https://starship.rs/) — prompt
- [fzf](https://github.com/junegunn/fzf) — fuzzy finder (also powers the wezterm pickers)
- [zoxide](https://github.com/ajeetdsouza/zoxide) — smarter `cd` (aliased to `cd`)
- [atuin](https://atuin.sh/) — shell history with fuzzy search and sync
- [ripgrep](https://github.com/BurntSushi/ripgrep) — grep, used by telescope live grep
- [fd](https://github.com/sharkdp/fd) — repo discovery for the wezterm sessionizer
- [aerospace](https://github.com/nikitabobko/AeroSpace) — tiling window manager
- [silicon](https://github.com/Aloxaf/silicon) — code screenshots from nvim
- [terminal-notifier](https://github.com/julienXX/terminal-notifier) — native notifications for Claude Code sessions (`brew install terminal-notifier`)
- [jq](https://jqlang.github.io/jq/) — used by the Claude Code status hook

## Setup

### Symlinks

On mac/linux:

```sh
ln -s ~/dotfiles/nvim ~/.config/nvim
ln -s ~/dotfiles/wezterm ~/.config/wezterm
ln -s ~/dotfiles/.zshrc ~/.zshrc
ln -s ~/dotfiles/.aerospace.toml ~/.aerospace.toml
ln -s ~/dotfiles/starship.toml ~/.config/starship.toml
ln -s ~/dotfiles/atuin/config.toml ~/.config/atuin/config.toml
```

On windows:

```sh
# for folders
mklink /d <windows_home>.config\wezterm <windows_home>\dotfiles\wezterm

# for files
mklink $WINDOWS_HOME\.wslconfig $WINDOWS_HOME\dotfiles\.wslconfig
```

### macOS tweaks

Disable the press-and-hold special character popup (so key repeat works in nvim):

```sh
defaults write -g ApplePressAndHoldEnabled -bool false
```

## WezTerm shortcuts

Leader key is <kbd>Ctrl</kbd>+<kbd>Space</kbd> (4s timeout).

### Panes

| Shortcut | Action |
|----------|--------|
| `Leader v` | Split right (50%) |
| `Leader s` / `Leader S` | Split down / up (50%) |
| `Leader a` | Small split right (20%) |
| `Leader h/j/k/l` | Move between panes |
| `Leader z` | Toggle pane zoom |
| `Leader w` / `Alt+w` | Close pane (with confirm) |
| `Leader q` | Rotate panes |
| `Ctrl+p` | Pane select mode |

### Tabs

| Shortcut | Action |
|----------|--------|
| `Alt+t` | New tab |
| `Alt+1..8` | Jump to tab |
| `Leader r` | Rename tab |
| `Cmd+w` | Close tab (workspace-aware, no dead-workspace limbo) |
| `Ctrl+x` | Copy mode |

### Workspaces & sessionizer

| Shortcut | Action |
|----------|--------|
| `Ctrl+e` | Pick among **open** workspaces (fzf, `j`/`k` to move) |
| `Tab` (inside picker) | Toggle between workspaces ⇄ Claude sessions picker |
| `Ctrl+i` | Claude sessions picker directly |
| `Leader f` | Sessionizer: fuzzy-find any repo under `~/workspace` (fd) and open/switch to it as a workspace |
| `Leader t` | Create named workspace |
| `Ctrl+]` | Toggle last active workspace |
| `Ctrl+/` | Built-in fuzzy workspace launcher |
| `Leader e` | Full launcher |

### Misc

| Shortcut | Action |
|----------|--------|
| `Ctrl/Cmd + =` / `-` / `0` | Font zoom in / out / reset (tracked so pickers match the zoom) |
| `Leader n` | Toggle fullscreen |
| `Leader u` | CPU monitor workspace (`top`) |
| `Leader d` | Debug overlay |

## Claude Code integration

`claude/claude-status-hook.sh` is wired into Claude Code hooks and records each session's status (`running`, `blocked`, `completed`, `idle`) to `/tmp/claude-wezterm-status`. WezTerm (`wezterm/claude_status.lua`) then:

- shows every session in the tab bar right status — one entry per workspace, worst status wins (◆ blocked > ● running > ✓ completed > ○ idle);
- treats `completed` as an unread marker: it flips to idle once you visit that workspace;
- provides the `Ctrl+i` picker — select a session to jump straight to the pane running Claude;
- fires a native macOS notification (terminal-notifier, osascript fallback) when a session completes or blocks **while WezTerm is in the background**.

## AeroSpace shortcuts

| Shortcut | Action |
|----------|--------|
| `Alt+h/j/k/l` | Focus window left/down/up/right |
| `Alt+Shift+h/j/k/l` | Move window |
| `Alt+1..9`, `Alt+a..z` | Switch workspace |
| `Alt+Shift+1..9/a..z` | Move window to workspace |
| `Alt+Tab` | Back-and-forth between last two workspaces |
| `Alt+Shift+Tab` | Move workspace to next monitor |
| `Alt+/` / `Alt+,` | Tiles / accordion layout |
| `Alt+Shift+-` / `Alt+Shift+=` | Resize window |
| `Alt+Shift+;` | Service mode (`Esc` reload config, `r` reset layout, `f` toggle floating, `Backspace` close all but current) |

## Neovim

Plugins managed with [lazy.nvim](https://github.com/folke/lazy.nvim). Leader key is <kbd>Space</kbd>; [which-key](https://github.com/folke/which-key.nvim) pops up the available mappings after the leader.

Highlights: lsp-zero (+ mason, cmp, conform format-on-save with prettier/eslint), telescope, treesitter, oil, fugitive, trouble, undotree, copilot, codecompanion, rose-pine theme.

### Key mappings

| Mapping | Action |
|---------|--------|
| `Ctrl+h/j/k/l` | Move between splits |
| `<leader>pf` / `<leader>ps` | Find file / live grep (telescope) |
| `<leader>pg` | Grep for input string |
| `<leader>pG` | Git files |
| `<leader>bf` | Find buffers |
| `<leader>po` / `<leader>pw` | Document / workspace symbols |
| `<leader>px` | Diagnostics |
| `<leader>pr` | Resume last search |
| `gd` / `gD` / `gr` / `gi` | Definition / declaration / references / implementations |
| `K` | Hover info |
| `ca` / `rn` | Code action / rename |
| `<leader>gg` / `<leader>gb` / `<leader>ga` | Git / Git blame / Git add . (fugitive) |
| `<leader>xx` | Toggle diagnostics list (trouble) |
| `<leader>u` | Undotree |
| `<leader>sf` | Scratch buffer |
| `<leader>ss` (visual) | Screenshot selection to clipboard (silicon) |
| `<leader>cc` / `<leader>ca` | CodeCompanion chat / actions |
| `<leader>md` | Markdown preview |

## Shell

`.zshrc` sets up:

- oh-my-zsh with the `simple` theme, `git` and `zsh-autosuggestions` plugins — prompt actually rendered by starship;
- `zoxide` replacing `cd` (frecency-based jumping: `cd <partial-name>`);
- `atuin` on `Ctrl+r` / up-arrow — fuzzy full-history search, enter runs immediately (tab to edit);
- fzf completions and keybindings;
- nvm, bun, go paths; `EDITOR=nvim` (vim over SSH);
- alias `c` = `clear`.
