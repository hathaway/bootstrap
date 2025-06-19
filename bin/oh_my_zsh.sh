#!/usr/bin/env bash

set -euo pipefail

# Utility functions
say()   { echo -e "🔹 $1"; }
bold()  { echo -e "\033[1m$1\033[0m"; }
prompt() {
  read -r -p "❓ $1 [y/N] " response
  [[ "$response" =~ ^[Yy](es)?$ ]]
}

bold "🔧 Oh My Zsh Setup Starting..."

# Ensure Zsh is installed
say "Checking for Zsh installation..."
if ! command -v zsh >/dev/null 2>&1; then
  say "\033[0;31mZsh is not installed. Installing via Homebrew...\033[0m"
  if ! command -v brew >/dev/null 2>&1; then
    say "\033[0;31mHomebrew is required but not found. Please install it first.\033[0m"
    exit 1
  fi
  brew install zsh
fi

# Xcode Command Line Tools
say "Checking for Xcode Command Line Tools..."
if ! xcode-select --print-path >/dev/null 2>&1; then
  say "📦 Installing Xcode Command Line Tools..."
  xcode-select --install
  say "\033[0;32m✅ Xcode Command Line Tools installation initiated. Please complete the installation if prompted.\033[0m"
  exit 0
else
  say "\033[0;32m✅ Xcode Command Line Tools are already installed.\033[0m"
fi

# Install Oh My Zsh
say "Checking for Oh My Zsh installation..."
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  say "📦 Installing Oh My Zsh..."
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  say "✅ Oh My Zsh is already installed."
fi

# Get full path to zsh
ZSH_PATH="/bin/zsh"

# Add to /etc/shells if not present
if ! grep -q "$ZSH_PATH" /etc/shells; then
  say "📜 Adding $ZSH_PATH to /etc/shells..."
  echo "$ZSH_PATH" | sudo tee -a /etc/shells
fi

# Change default shell if not already set
if [[ "$SHELL" != "$ZSH_PATH" ]]; then
  say "⚙️ Changing shell to Zsh..."
  chsh -s "$ZSH_PATH"
  say "\033[0;32m✅ Default shell changed to Zsh. Please restart your terminal session.\033[0m"
else
  say "✅ Zsh is already your default shell."
fi

# Install zsh-autosuggestions plugin
say "Checking for zsh-autosuggestions plugin installation..."
if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]]; then
  say "📦 Installing zsh-autosuggestions plugin..."
  git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
else
  say "✅ zsh-autosuggestions plugin is already installed."
fi

# Add zsh-autosuggestions to ~/.zshrc plugins list
if ! grep -q "zsh-autosuggestions" ~/.zshrc; then
  say "📜 Adding zsh-autosuggestions to plugins list in ~/.zshrc..."
  sed -i '' '/^plugins=/ s/)/ zsh-autosuggestions)/' ~/.zshrc
fi

bold "✅ Oh My Zsh setup complete!"
