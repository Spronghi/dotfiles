# dotfiles

Keep the ball rolling

- [wezterm](https://wezfurlong.org/wezterm/index.html)
- [nvim](https://neovim.io/)
- [cascadia mono](https://github.com/microsoft/cascadia-code).
- [oh-my-zsh](https://ohmyz.sh/#install)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions?tab=readme-ov-file)
- [zsh-npm-scripts-autocomplete](https://github.com/grigorii-zander/zsh-npm-scripts-autocomplete)
- [fzf](https://github.com/junegunn/fzf)
- [zoxide](https://github.com/ajeetdsouza/zoxide)
- [silicon](https://github.com/Aloxaf/silicon)
- [ripgrep](https://github.com/BurntSushi/ripgrep)
- [aerospace](https://github.com/nikitabobko/AeroSpace)
- [atuin](https://atuin.sh/)
- [terminal-notifier](https://github.com/julienXX/terminal-notifier) — native notifications for claude sessions (`brew install terminal-notifier`)
- [fd](https://github.com/sharkdp/fd) — repo discovery for the wezterm sessionizer

## Create symlinks

On mac/linux:

```sh
#!/bin/bash

ln -s ~/dotfiles/nvim ~/.config/nvim
```

On windows:

```sh
# for folders
mklink /d <windows_home>.config\wezterm <windows_home>\dotfiles\wezterm

# for files
mklink $WINDOWS_HOME\.wslconfig $WINDOWS_HOME\dotfiles\.wslconfig
```

## Setup Commands

On mac, is better to disable the special character info box

```sh
defaults write -g ApplePressAndHoldEnabled -bool false
```
