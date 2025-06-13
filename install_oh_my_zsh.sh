#!/usr/bin/env bash

set -euo pipefail

# Colors (optional)
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "🔧 Checking for Zsh installation..."

# Ensure Zsh is installed
if ! command -v zsh >/dev/null 2>&1; then
  echo -e "${RED}Zsh is not installed. Installing via Homebrew...${NC}"
  if ! command -v brew >/dev/null 2>&1; then
    echo -e "${RED}Homebrew is required but not found. Please install it first.${NC}"
    exit 1
  fi
  brew install zsh
fi

# Ensure Git is installed
echo "🔧 Checking for Git installation..."
if ! command -v git >/dev/null 2>&1; then
  echo -e "${RED}Git is not installed. Installing via Xcode Command Line Tools...${NC}"
  if ! xcode-select --print-path >/dev/null 2>&1; then
    echo "📦 Installing Xcode Command Line Tools..."
    xcode-select --install
    echo -e "${GREEN}✅ Xcode Command Line Tools installation initiated. Please complete the installation if prompted.${NC}"
    exit 0
  else
    echo -e "${GREEN}✅ Xcode Command Line Tools are already installed.${NC}"
  fi
else
  echo "✅ Git is already installed."
fi

# Install Oh My Zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "📦 Installing Oh My Zsh..."
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "✅ Oh My Zsh is already installed."
fi

# Get full path to zsh
ZSH_PATH="$(command -v zsh)"

# Add to /etc/shells if not present
if ! grep -q "$ZSH_PATH" /etc/shells; then
  echo "📜 Adding $ZSH_PATH to /etc/shells..."
  echo "$ZSH_PATH" | sudo tee -a /etc/shells
fi

# Change default shell if not already set
if [[ "$SHELL" != "$ZSH_PATH" ]]; then
  echo "⚙️ Changing shell to Zsh..."
  chsh -s "$ZSH_PATH"
  echo -e "${GREEN}✅ Default shell changed to Zsh. Please restart your terminal session.${NC}"
else
  echo "✅ Zsh is already your default shell."
fi
