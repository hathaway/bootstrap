#!/bin/bash

set -e

# Utility functions
say()   { echo -e "🔹 $1"; }
bold()  { echo -e "\033[1m$1\033[0m"; }
prompt() {
  read -r -p "❓ $1 [y/N] " response
  [[ "$response" =~ ^[Yy](es)?$ ]]
}

ensure_gh_scope() {
  local scope="$1"
  if ! gh auth status 2>/dev/null | grep -q "$scope"; then
    say "🔑 Missing GitHub scope: '$scope'. Requesting it now..."
    gh auth refresh -h github.com -s "$scope"
  else
    say "✅ GitHub scope '$scope' already granted."
  fi
}

bold "🔧 Git + GPG + GitHub SSH Setup with 1Password Lifecycle"

# --- Prompt for Git identity ---
GIT_NAME_DEFAULT=$(git config --global user.name || echo "")
GIT_EMAIL_DEFAULT=$(git config --global user.email || echo "")
read -p "📝 Enter your Git name [${GIT_NAME_DEFAULT}]: " GIT_NAME
GIT_NAME=${GIT_NAME:-$GIT_NAME_DEFAULT}
read -p "📧 Enter your Git email [${GIT_EMAIL_DEFAULT}]: " GIT_EMAIL
GIT_EMAIL=${GIT_EMAIL:-$GIT_EMAIL_DEFAULT}

# --- Setup 1Password naming conventions ---
GIT_NAME_AND_EMAIL="$GIT_NAME <$GIT_EMAIL>"
COMPUTER_NAME="$(scutil --get ComputerName | tr ' ' '-')"
GPG_ITEM_TITLE="GPG Signing Key for ${GIT_NAME_AND_EMAIL}"
GPG_FILENAME="gpg-armored-key.asc"
SSH_ITEM_TITLE="GitHub SSH Key for ${GIT_NAME_AND_EMAIL} on ${COMPUTER_NAME}"
SSH_KEY_PATH="$HOME/.ssh/id_ed25519_github"
SSH_PUBKEY_PATH="${SSH_KEY_PATH}.pub"
TEMP_SSH_KEY_PATH="/tmp/id_ed25519_github"
TEMP_GPG_KEY_PATH="/tmp/$GPG_FILENAME"
GPG_PUBKEY_PATH="/tmp/pubkey.asc"

# --- Install dependencies ---
say "Ensuring tools are installed..."
FORMULA_PACKAGES=("git" "gh" "gnupg" "pinentry-mac")
for package in "${FORMULA_PACKAGES[@]}"; do
  if ! brew list --formula | grep -qx "$package"; then
    say "Installing $package..."
    brew install "$package"
  fi
done
CASK_PACKAGES=("1password-cli")
for package in "${CASK_PACKAGES[@]}"; do
  if ! brew list --cask | grep -qx "$package"; then
    say "Installing $package..."
    brew install --cask "$package"
  fi
done

# --- Git configuration ---
say "Configuring Git..."
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch main
git config --global color.ui auto
git config --global pull.rebase false


# --- CLI tool checks ---
command -v op >/dev/null || { say "❌ Install 1Password CLI"; exit 1; }
command -v gh >/dev/null || { say "❌ Install GitHub CLI"; exit 1; }

# --- Auth checks ---
if ! op account list | grep -q "SIGNED_IN"; then
  say "Signing into 1Password..."
  eval "$(op signin)"
fi

if ! gh auth status &>/dev/null; then
  say "Logging into GitHub..."
  gh auth login
fi

# --- pinentry setup ---
mkdir -p ~/.gnupg
echo "pinentry-program /opt/homebrew/bin/pinentry-mac" > ~/.gnupg/gpg-agent.conf
killall gpg-agent || true

# --- GPG KEY: Load or Generate and Store in 1P ---
say "🔍 Checking for existing secret GPG key in local keyring..."
if gpg --list-secret-keys --with-colons "$GIT_NAME_AND_EMAIL" 2>/dev/null | grep -q '^sec'; then
  say "✅ Found existing GPG secret key for $GIT_NAME_AND_EMAIL in local keyring."
else
  say "Checking for GPG key in 1Password..."
  if op document get "$GPG_ITEM_TITLE" --out-file "$TEMP_GPG_KEY_PATH" --force 2>/dev/null; then
    say "✅ Found GPG key in 1Password."
    gpg --import "$TEMP_GPG_KEY_PATH"
  else
    say "🔐 Generating new GPG key..."
    gpg --pinentry-mode loopback --passphrase '' --quick-key-gen "$GIT_NAME_AND_EMAIL" rsa4096 sign none

    say "📦 Exporting new GPG key for 1Password..."
    gpg --armor --export-secret-keys "$GIT_NAME_AND_EMAIL" > "$TEMP_GPG_KEY_PATH"
    op document create "$TEMP_GPG_KEY_PATH" --title "$GPG_ITEM_TITLE"
    say "🔐 New GPG key stored in 1Password as '$GPG_ITEM_TITLE'"
  fi
fi

KEY_ID=$(gpg --list-secret-keys --keyid-format=long "$GIT_NAME_AND_EMAIL" | grep 'sec' | awk '{print $2}' | cut -d'/' -f2)

# Ask user and ensure correct GitHub scope
if prompt "Upload GPG public key to GitHub? ($KEY_ID)"; then
  ensure_gh_scope "admin:gpg_key"

  # --- Export GPG Public Key for GitHub Upload ---
  say "📤 Preparing GPG public key for GitHub..."
  gpg --armor --export "$GIT_NAME_AND_EMAIL" > "$GPG_PUBKEY_PATH"

  # Sanity check: ensure the key is a public key
  if ! grep -q "BEGIN PGP PUBLIC KEY BLOCK" "$GPG_PUBKEY_PATH"; then
    say "❌ Exported key is not a valid GPG public key. Aborting upload."
    exit 1
  fi

  gh gpg-key add "$GPG_PUBKEY_PATH" --title "$GPG_ITEM_TITLE"

  say "✅ GPG key uploaded to GitHub."
else
  pbcopy < "$GPG_PUBKEY_PATH"
  say "📋 Public GPG key copied to clipboard."
fi

# --- GPG Signing Key Configuration ---
say "Configuring git to use GPG signing key..."
git config --global user.signingkey "$KEY_ID"
git config --global commit.gpgsign true
say "✅ Git configured to use GPG signing key. ($KEY_ID)"

if [ ! -f "$SSH_KEY_PATH" ]; then
  # --- SSH KEY: Check 1Password before generating ---
  say "Checking for GitHub SSH key in 1Password..."
  if op document get "$(basename "$TEMP_SSH_KEY_PATH")" --item "$SSH_ITEM_TITLE" > "$TEMP_SSH_KEY_PATH" 2>/dev/null; then
    say "✅ Found SSH key in 1Password. Installing locally..."
    mkdir -p ~/.ssh
    mv "$TEMP_SSH_KEY_PATH" "$SSH_KEY_PATH"
    chmod 600 "$SSH_KEY_PATH"
  else
    say "🛠 No SSH key found in 1Password. Generating new one..."
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY_PATH" -N ""
    op document create "$SSH_KEY_PATH" --title "$SSH_ITEM_TITLE"
    say "🔐 SSH key stored in 1Password as '$SSH_ITEM_TITLE'"
  fi

  # --- Add key to agent & macOS Keychain ---
  eval "$(ssh-agent -s)"
  ssh-add --apple-use-keychain "$SSH_KEY_PATH"
fi

# --- Upload to GitHub ---
if [ -f "$SSH_PUBKEY_PATH" ] && prompt "Upload SSH public key to GitHub?"; then
  ensure_gh_scope "admin:public_key"

  gh ssh-key add "$SSH_PUBKEY_PATH" --title "$COMPUTER_NAME-github-ssh"
  say "✅ SSH public key uploaded."
fi

# --- Use SSH instead of HTTPS? ---
if prompt "Use SSH instead of HTTPS for GitHub remotes?"; then
  git config --global url."git@github.com:".insteadOf "https://github.com/"
  say "🔁 GitHub remotes will now use SSH."
fi

# --- Cleanup ---
rm -f "$TEMP_GPG_KEY_PATH"
rm -f "$TEMP_SSH_KEY_PATH"

bold "🎉 All set! Git is configured to sign commits and use SSH."
