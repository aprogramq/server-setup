#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]] && ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required but is not installed." >&2
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This script supports Ubuntu/Debian systems with apt-get." >&2
  exit 1
fi

ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}"

as_root() {
  if [[ "${EUID}" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

run_apt_update() {
  as_root apt-get update
  as_root env DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
}

install_packages() {
  as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates \
    curl \
    git \
    mosh \
    tmux \
    vim \
    zsh
}

install_oh_my_zsh() {
  if [[ -d "${HOME}/.oh-my-zsh" ]]; then
    echo "oh-my-zsh is already installed."
    return
  fi

  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_zsh_plugins() {
  mkdir -p "${ZSH_CUSTOM_DIR}/plugins"

  if [[ ! -d "${ZSH_CUSTOM_DIR}/plugins/zsh-autosuggestions" ]]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM_DIR}/plugins/zsh-autosuggestions"
  fi

  if [[ ! -d "${ZSH_CUSTOM_DIR}/plugins/zsh-syntax-highlighting" ]]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "${ZSH_CUSTOM_DIR}/plugins/zsh-syntax-highlighting"
  fi

  if [[ ! -d "${ZSH_CUSTOM_DIR}/plugins/zsh-completions" ]]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-completions "${ZSH_CUSTOM_DIR}/plugins/zsh-completions"
  fi
}

configure_zshrc() {
  local zshrc="${HOME}/.zshrc"

  if [[ ! -f "${zshrc}" ]]; then
    cp "${HOME}/.oh-my-zsh/templates/zshrc.zsh-template" "${zshrc}"
  fi

  if grep -q '^plugins=' "${zshrc}"; then
    sed -i 's/^plugins=.*/plugins=(git vi-mode zsh-autosuggestions zsh-syntax-highlighting zsh-completions)/' "${zshrc}"
  else
    printf '\nplugins=(git vi-mode zsh-autosuggestions zsh-syntax-highlighting zsh-completions)\n' >>"${zshrc}"
  fi

  if ! grep -q '^VI_MODE_ESC_INSERT=jj$' "${zshrc}"; then
    if grep -q '^source .*oh-my-zsh.sh' "${zshrc}"; then
      sed -i '/^source .*oh-my-zsh.sh/i VI_MODE_ESC_INSERT=jj' "${zshrc}"
    else
      printf '\nVI_MODE_ESC_INSERT=jj\n' >>"${zshrc}"
    fi
  fi

  if grep -q '^export KEYTIMEOUT=1$' "${zshrc}"; then
    sed -i 's/^export KEYTIMEOUT=1$/export KEYTIMEOUT=25/' "${zshrc}"
  fi

  if ! grep -q "bindkey -M viins 'jj' vi-cmd-mode" "${zshrc}"; then
    cat >>"${zshrc}" <<'EOF'

# Vim mode in the zsh prompt, with jj acting like Esc.
bindkey -v
export KEYTIMEOUT=25
bindkey -M main 'jj' vi-cmd-mode
bindkey -M viins 'jj' vi-cmd-mode
EOF
  fi
}

configure_vim() {
  local vimrc="${HOME}/.vimrc"

  if ! grep -q 'inoremap jj <Esc>' "${vimrc}" 2>/dev/null; then
    cat >>"${vimrc}" <<'EOF'

" Press jj quickly in insert mode to leave insert mode.
inoremap jj <Esc>
EOF
  fi
}

configure_tmux_autostart() {
  local zshrc="${HOME}/.zshrc"

  if grep -q 'tmux new-session -A -s main' "${zshrc}" 2>/dev/null; then
    return
  fi

  cat >>"${zshrc}" <<'EOF'

# Automatically attach to tmux when logging in over SSH.
if [[ -n "${SSH_CONNECTION:-}" && -z "${TMUX:-}" && -t 1 ]] && command -v tmux >/dev/null 2>&1; then
  tmux new-session -A -s main
fi
EOF
}

configure_tmux() {
  local tmux_conf="${HOME}/.tmux.conf"

  if grep -q '# Server setup tmux OSC 52 clipboard config' "${tmux_conf}" 2>/dev/null; then
    return
  fi

  cat >>"${tmux_conf}" <<'EOF'

# Server setup tmux config
set -g mode-keys vi
set -g set-clipboard on
set -as terminal-features ',xterm-256color:clipboard,screen-256color:clipboard,tmux-256color:clipboard'
set -as terminal-overrides ',*:Ms=\E]52;c;%p2%s\7'
unbind-key [
bind-key v copy-mode
bind-key -T copy-mode-vi j send-keys -X scroll-down
bind-key -T copy-mode-vi l send-keys -X scroll-up
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'tmux load-buffer -w -'

# Server setup tmux OSC 52 clipboard config
bind-key -T copy-mode-vi Y send-keys -X copy-pipe-and-cancel 'sh -c '\''printf "\033]52;c;%s\007" "$(base64 | tr -d "\n")"'\'''
EOF
}

set_default_shell() {
  local zsh_path

  zsh_path="$(command -v zsh)"
  if [[ "${SHELL}" == "${zsh_path}" ]]; then
    echo "zsh is already the default shell."
    return
  fi

  if [[ "${EUID}" -eq 0 ]]; then
    chsh -s "${zsh_path}" root
  else
    chsh -s "${zsh_path}"
  fi
  echo "Default shell changed to zsh. Log out and log back in to apply it."
}

main() {
  run_apt_update
  install_packages
  install_oh_my_zsh
  install_zsh_plugins
  configure_zshrc
  configure_vim
  configure_tmux_autostart
  configure_tmux
  set_default_shell

  echo "Ubuntu update, mosh, zsh, oh-my-zsh, tmux, plugins, and Vim jj mapping are configured."
}

main "$@"
