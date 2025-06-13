#!/usr/bin/env bash

set -euo pipefail

# Utility functions
say()   { echo -e "🔹 $1"; }
bold()  { echo -e "\033[1m$1\033[0m"; }
prompt() {
  read -r -p "❓ $1 [y/N] " response
  [[ "$response" =~ ^[Yy](es)?$ ]]
}

fetch_remote_brewfiles() {
  local repo="$1"
  local branch="$2"
  local base_url="https://raw.githubusercontent.com/$repo/$branch"
  local profiles=("Brewfile" "Brewfile.work" "Brewfile.personal" "Brewfile.dev" "Brewfile.full")

  say "🔍 Checking for available Brewfiles in $repo@$branch..."

  declare -a available=()
  for file in "${profiles[@]}"; do
    if curl --head --silent --fail "$base_url/$file" > /dev/null; then
      available+=("$file")
    fi
  done

  if [[ ${#available[@]} -eq 0 ]]; then
    say "⚠️ No Brewfiles found in repo."
    return 1
  fi

  echo "📄 Available Brewfiles:"
  for i in "${!available[@]}"; do
    echo "$((i+1))) ${available[$i]}"
  done

  read -r -p "Enter number to select Brewfile: " index
  local selected="${available[$((index-1))]}"
  if [[ -z "$selected" ]]; then
    say "Invalid selection. Skipping."
    return 1
  fi

  say "📦 Downloading $selected..."
  local tmpfile
  tmpfile=$(mktemp)
  if curl -fsSL "$base_url/$selected" -o "$tmpfile"; then
    brew bundle --file="$tmpfile"
    say "✅ Brew bundle from $selected complete."
    rm "$tmpfile"
  else
    say "❌ Failed to download $selected"
    return 1
  fi
}

bold "🍺 Homebrew Setup Starting..."

# Install Homebrew if needed
if ! command -v brew >/dev/null 2>&1; then
  say "Homebrew not found. Installing..."
  say "You may be prompted for your password to install Homebrew (via sudo)..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  elif [[ -x /usr/local/bin/brew ]]; then
    export PATH="/usr/local/bin:$PATH"
    eval "$(/usr/local/bin/brew shellenv)"
    echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
  else
    say "⚠️ Brew not found in expected paths. Make sure it's installed correctly."
  fi

  say "✅ Homebrew install complete."
else
  say "Homebrew is already installed."
fi

say "Updating Homebrew..."
brew update

# Upgrade prompt
if prompt "Run 'brew upgrade' to update installed packages?"; then
  say "Upgrading packages..."
  brew upgrade
else
  say "Skipped upgrading."
fi

# Bundle prompt
if prompt "Run 'brew bundle' to install from a Brewfile?"; then
  echo "📦 Choose Brewfile source:"
  echo "1) Use local ~/Brewfile"
  echo "2) Download from GitHub repo"
  read -r -p "Enter 1 or 2: " bundle_choice

  if [[ "$bundle_choice" == "1" ]]; then
    local_brewfile="$HOME/Brewfile"
    if [[ -f "$local_brewfile" ]]; then
      say "Using local Brewfile at $local_brewfile..."
      brew bundle --file="$local_brewfile"
    else
      say "❌ No Brewfile found at $local_brewfile"
    fi

  elif [[ "$bundle_choice" == "2" ]]; then
    read -r -p "🔗 Enter GitHub repo (e.g. user/repo or user/repo@branch): " repo_input
    repo="${repo_input%@*}"
    branch="${repo_input#*@}"
    [[ "$repo_input" == "$branch" ]] && branch="HEAD"

    fetch_remote_brewfiles "$repo" "$branch" || say "⚠️ Skipped remote bundle."
  else
    say "Invalid option. Skipping brew bundle."
  fi
else
  say "Skipped brew bundle."
fi

# Cleanup prompt
if prompt "Run 'brew cleanup' to remove unused files?"; then
  say "Cleaning up..."
  brew cleanup
else
  say "Skipped cleanup."
fi

bold "✅ Homebrew setup complete!"
