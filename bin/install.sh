#!/usr/bin/env bash

set -euo pipefail

# Utility functions
say()   { echo -e "🔹 $1"; }
bold()  { echo -e "\033[1m$1\033[0m"; }

### Ask for sudo up front
require_sudo_session() {
  say "🔐 Requesting sudo access..."
  sudo -v
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}

bold "🚀 Starting full system setup..."

require_sudo_session

# Run Oh My Zsh setup
bold "🔧 Running Oh My Zsh setup..."
say "📥 Downloading Oh My Zsh script..."
curl -fsSL -o /tmp/oh_my_zsh.sh https://raw.githubusercontent.com/your-repo/your-branch/dotfiles/bin/oh_my_zsh.sh
chmod +x /tmp/oh_my_zsh.sh
/tmp/oh_my_zsh.sh

# Run Homebrew setup
bold "🍺 Running Homebrew setup..."
say "📥 Downloading Homebrew script..."
curl -fsSL -o /tmp/homebrew.sh https://raw.githubusercontent.com/your-repo/your-branch/dotfiles/bin/homebrew.sh
chmod +x /tmp/homebrew.sh
/tmp/homebrew.sh

# Run macOS configuration
bold "⚙️ Running macOS configuration..."
say "📥 Downloading macOS configuration script..."
curl -fsSL -o /tmp/macos.sh https://raw.githubusercontent.com/your-repo/your-branch/dotfiles/bin/macos.sh
chmod +x /tmp/macos.sh
/tmp/macos.sh

bold "✅ Full system setup complete!"
