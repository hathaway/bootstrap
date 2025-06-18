#!/bin/bash

set -e

# Utility functions
say()   { echo -e "🔹 $1"; }
bold()  { echo -e "\033[1m$1\033[0m"; }
prompt() {
  read -r -p "❓ $1 [y/N] " response
  [[ "$response" =~ ^[Yy](es)?$ ]]
}

# --- Install packages ---
FORMULA_PACKAGES=("asdf")
for package in "${FORMULA_PACKAGES[@]}"; do
  if ! brew list --formula | grep -qx "$package"; then
    say "Installing $package..."
    brew install "$package"
  fi
done

# --- Install packages ---
FORMULA_CASKS=("docker")
for package in "${FORMULA_CASKS[@]}"; do
  if ! brew list --cask | grep -qx "$package"; then
    say "Installing $package..."
    brew install "$package"
  fi
done

# --- asdf ---
say "Configuring shell for asdf..."
if ! grep -q 'export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"' ~/.zshrc; then
  sed -i '' '/^export/!b; :a; n; $!ba; a\
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
' ~/.zshrc
  source ~/.zshrc
  say "Finished configuring shell for asdf."
fi

# --- Ruby ---
if ! asdf plugin list | grep -q ruby; then
  say "Installing Ruby asdf plugin..."
  asdf plugin install ruby
fi
if ! asdf list ruby | grep -q "$(asdf latest ruby)"; then
  say "Installing Ruby..."
  asdf install ruby latest
fi

# --- Docker ---
if [ ! -f ~/.oh-my-zsh/completions/_docker ]; then
  say "Configuring Docker completions..."
  mkdir -p ~/.oh-my-zsh/completions
  docker completion zsh > ~/.oh-my-zsh/completions/_docker
fi

# mkdir -p ~/.config/fish/completions
# docker completion fish > ~/.config/fish/completions/docker.fish
