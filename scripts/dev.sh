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

# --- Node.js ---
if ! asdf plugin list | grep -q nodejs; then
  say "Installing Node.js asdf plugin..."
  asdf plugin add nodejs
fi
if ! asdf list nodejs | grep -q "$(asdf latest nodejs)"; then
  say "Installing Node.js..."
  asdf install nodejs latest
fi

# --- Install npm packages ---
NPM_PACKAGES=("@anthropic-ai/claude-code")
for package in "${NPM_PACKAGES[@]}"; do
  if ! npm list -g "$package" &>/dev/null; then
    say "Installing npm package: $package..."
    npm install -g "$package"
  fi
done

# --- asdf ---
if ! grep -q 'export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"' ~/.zshrc; then
  say "Configuring shell for asdf..."
  echo 'export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"' >> ~/.zshrc
  source ~/.zshrc
  say "Finished configuring shell for asdf."
fi

# --- Ruby ---
if ! asdf plugin list | grep -q ruby; then
  say "Installing Ruby asdf plugin..."
  asdf plugin add ruby
fi
if ! asdf list ruby | grep -q "$(asdf latest ruby)"; then
  say "Installing Ruby..."
  asdf install ruby latest
fi

# --- Install Ruby Gems ---
RUBY_GEMS=("ruby-lsp" "solargraph")
for gem in "${RUBY_GEMS[@]}"; do
  if ! gem list | grep -q "^$gem "; then
    say "Installing Ruby gem: $gem..."
    gem install "$gem"
  fi
done



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

if prompt "Would you like to copy SSH keys from 1Password?"; then
  say "Signing into 1Password for SSH keys..."
  eval "$(op signin)"

  # --- Copy SSH keys from 1Password into ~/.ssh ---
  SSH_KEYS=("shield-production-bastion" "shield-staging-bastion" "echelon-production-bastion" "echelon-staging-bastion" "bracket-production")
  for ssh_key in "${SSH_KEYS[@]}"; do
    if op item get "$ssh_key" --field "private key" --reveal > "$HOME/.ssh/$ssh_key" 2>&1; then
      chmod 600 $HOME/.ssh/$ssh_key
      say "✅ Copied SSH key $ssh_key from 1Password to $HOME/.ssh/$ssh_key."
    fi
  done

  say "Signing out of 1Password..."
  eval "$(op signout)"
fi

if prompt "Would you like to copy AWS files from 1Password?"; then
  say "Signing into 1Password for AWS files..."
  eval "$(op signin)"

  # --- Copy AWS files from 1Password into ~/.aws ---
  AWS_FILES=("config" "credentials")
  for file in "${AWS_FILES[@]}"; do
    if op document get "aws-$file" --out-file "$HOME/.aws/$file" --force >/dev/null 2>&1; then
      chmod 600 $HOME/.aws/$file
      say "✅ Copied $file from 1Password to $HOME/.aws/$file."
    fi
  done

  say "Signing out of 1Password..."
  eval "$(op signout)"
fi

# --- Create ~/.local/bin and move scripts ---
local_bin="$HOME/.local/bin"
if [[ ! -d "$local_bin" ]]; then
  say "Creating ~/.local/bin directory..."
  mkdir -p "$local_bin"
fi

if ! grep -q 'export PATH="$local_bin:$PATH"' ~/.zshrc; then
  say "Configuring shell for ~/.local/bin..."
  echo 'export PATH="$local_bin:$PATH"' >> ~/.zshrc
  say "Finished configuring shell for ~/.local/bin."
fi

say "Copying scripts from bin folder to ~/.local/bin..."
for script in bin/*; do
  if [[ -f "$script" ]]; then
    cp "$script" "$local_bin"
    chmod +x "$local_bin/$(basename "$script")"
    say "Copied and made executable: $(basename "$script")"
  fi
done
