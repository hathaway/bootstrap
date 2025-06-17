#!/bin/bash

set -e

# Utility functions
say()   { echo -e "🔹 $1"; }
bold()  { echo -e "\033[1m$1\033[0m"; }
prompt() {
  read -r -p "❓ $1 [y/N] " response
  [[ "$response" =~ ^[Yy](es)?$ ]]
}

# --- Install asdf ---
FORMULA_PACKAGES=("asdf")
for package in "${FORMULA_PACKAGES[@]}"; do
  if ! brew list --formula | grep -qx "$package"; then
    say "Installing $package..."
    brew install "$package"
  fi
done

sed -i '' '/^export/!b; :a; n; $!ba; a\
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
' ~/.zshrc

source ~/.zshrc

say "Finished installing asdf."
