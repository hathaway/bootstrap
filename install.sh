#!/usr/bin/env bash

set -euo pipefail

# Helper to safely source a URL or exit with error
safe_source() {
  local url="$1"
  if curl -fsSL "$url" -o /tmp/$$.sourced_script; then
    source /tmp/$$.sourced_script
    rm /tmp/$$.sourced_script
  else
    echo "❌ Failed to download or source: $url"
    exit 1
  fi
}

echo "🔧 Starting dotfiles installation..."

safe_source "https://raw.githubusercontent.com/hathaway/dotfiles/HEAD/lib/echos.sh"
safe_source "https://raw.githubusercontent.com/hathaway/dotfiles/HEAD/lib/requirers.sh"
safe_source "https://raw.githubusercontent.com/hathaway/dotfiles/HEAD/bin/homebrew"

echo "✅ Dotfiles install script completed."
