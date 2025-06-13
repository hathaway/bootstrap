#!/usr/bin/env bash

set -euo pipefail

# Utility functions
say()   { echo -e "🔹 $1"; }
bold()  { echo -e "\033[1m$1\033[0m"; }
prompt() {
  read -r -p "❓ $1 [y/N] " response
  [[ "$response" =~ ^[Yy](es)?$ ]]
}

bold "🍺 Homebrew Setup Starting..."

# Check/install Homebrew
if ! command -v brew >/dev/null 2>&1; then
  say "Homebrew not found. Installing..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null)" || \
  eval "$(/usr/local/bin/brew shellenv 2>/dev/null)" || true
else
  say "Homebrew already installed."
fi

say "Updating Homebrew..."
brew update

# Upgrade installed packages
if prompt "Run 'brew upgrade' to update installed packages?"; then
  say "Upgrading packages..."
  brew upgrade
  say "Packages upgraded."
else
  say "Skipped upgrading."
fi

# Run Brewfile
if prompt "Run 'brew bundle' to install from a Brewfile?"; then
  echo "🔧 Choose Brewfile source:"
  echo "1) Use local ~/Brewfile"
  echo "2) Download from GitHub URL"
  read -r -p "Enter 1 or 2: " choice

  if [[ "$choice" == "1" ]]; then
    BREWFILE="$HOME/Brewfile"
    if [[ -f "$BREWFILE" ]]; then
      say "Using local Brewfile at $BREWFILE..."
      brew bundle --file="$BREWFILE"
      say "Brew bundle complete."
    else
      say "No Brewfile found at $BREWFILE."
    fi
  elif [[ "$choice" == "2" ]]; then
    read -r -p "🌐 Enter raw GitHub URL to the Brewfile (e.g. https://raw.githubusercontent.com/user/repo/branch/Brewfile): " url
    TEMP_BREWFILE="$(mktemp)"
    if curl -fsSL "$url" -o "$TEMP_BREWFILE"; then
      say "Downloaded Brewfile. Running bundle..."
      brew bundle --file="$TEMP_BREWFILE"
      say "Brew bundle complete."
      rm "$TEMP_BREWFILE"
    else
      say "Failed to download Brewfile from URL."
    fi
  else
    say "Invalid choice. Skipping brew bundle."
  fi
else
  say "Skipped brew bundle."
fi

# Cleanup
if prompt "Run 'brew cleanup' to remove unused files?"; then
  say "Cleaning up..."
  brew cleanup
  say "Cleanup done."
else
  say "Skipped cleanup."
fi

bold "✅ Homebrew setup complete!"
