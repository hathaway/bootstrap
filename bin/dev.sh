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
if ! grep -q 'export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"' ~/.zshrc; then
  say "Configuring shell for asdf..."
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

if ! gh auth status &>/dev/null; then
  say "Logging into GitHub..."
  gh auth login
fi

# --- Clone repositories ---
REPOS=("mailprotector/ops-tools")
for repo in "${REPOS[@]}"; do
  if [ ! -d ~/Projects/$repo ]; then
    say "Cloning $repo..."
    gh repo clone "$repo" ~/Projects/$repo
  fi
done

# --- Auth checks ---
if ! op account list | grep -q "SIGNED_IN"; then
  say "Signing into 1Password..."
  eval "$(op signin)"
fi

# --- Copy SSH keys from 1Password into ~/.ssh ---
SSH_KEYS=("shield-production-bastion" "shield-staging-bastion" "echelon-production-bastion" "echelon-staging-bastion" "bracket-production")
for ssh_key in "${SSH_KEYS[@]}"; do
  if op read --out-file "$HOME/.ssh/$ssh_key" "op://Employee/$ssh_key/private key?ssh-format=openssh" --force >/dev/null 2>&1; then
    say "✅ Copied SSH key $ssh_key from 1Password to $HOME/.ssh/$ssh_key."
  fi
done
