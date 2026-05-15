# Ubuntu Server Setup

This script updates Ubuntu, installs `mosh`, `zsh`, `oh-my-zsh`, Vim-mode and completion plugins, and configures `jj` as an insert-mode escape shortcut in Vim and the zsh prompt.

## Usage

After the repository is published on GitHub, run it with one command:

```bash
curl -fsSL https://raw.githubusercontent.com/aprogramq/server-setup/main/ubuntu.sh | bash
```


Local run:

```bash
chmod +x ubuntu.sh
./ubuntu.sh
```

The script can be run as `root` or as a regular user with `sudo` access.

## What It Installs And Configures

- system packages: `ca-certificates`, `curl`, `git`, `mosh`, `tmux`, `vim`, `zsh`
- `oh-my-zsh`
- `oh-my-zsh` plugins: `git`, `vi-mode`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-completions`
- `~/.vimrc`: `inoremap jj <Esc>`
- `~/.zshrc`: Vim mode and `jj` as `Esc` in the command line, `VI_MODE_ESC_INSERT=jj`, `KEYTIMEOUT=25`
- `tmux` autostart on SSH login: attaches to the `main` session or creates it
- `~/.tmux.conf`: copy mode on `Ctrl-b v`, default `Ctrl-b [` disabled, copy-mode scrolling with `j`/`l`, copying with `y` or `Y` to the local clipboard through OSC 52

After the shell is changed, log out and log back in.
