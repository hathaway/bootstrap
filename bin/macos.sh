#!/usr/bin/env bash
set -euo pipefail

# Utility functions
say()   { echo -e "🔹 $1"; }
bold()  { echo -e "\033[1m$1\033[0m"; }
prompt() {
  read -r -p "❓ $1 [y/N] " response
  [[ "$response" =~ ^[Yy](es)?$ ]]
}

remove_quarantine_safe() {
  local app_path="$1"
  local tmp="/tmp/$(basename "$app_path")"
  if [[ -d "$app_path" ]]; then
    echo "🧼 Stripping quarantine from: $app_path"
    sudo mv "$app_path" "$tmp"
    xattr -dr com.apple.quarantine "$tmp"
    sudo mv "$tmp" "/Applications/"
  else
    echo "⚠️ App not found: $app_path"
  fi
}

bold "⚙️ Configuring macOS system preferences..."

### Ask for sudo up front
require_sudo_session() {
  say "🔐 Requesting sudo access..."
  sudo -v
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}
require_sudo_session

### Prompt for computer name / hostname
if prompt "Would you like to set a name for your computer?"; then
  read -r -p "📛 Enter a name for your computer: " computer_name
  sudo scutil --set ComputerName "$computer_name"
  sudo scutil --set HostName "$computer_name"
  sudo scutil --set LocalHostName "$computer_name"
  sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$computer_name"
else
  say "Skipping computer naming."
fi

### Dock settings
say "🔧 Configuring Dock..."
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 48
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock showAppExposeGestureEnabled -bool true

### Disable app quarantine warning
echo "🚫 Disabling 'Are you sure you want to open this?' prompts..."
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Optional: strip quarantine flag from known apps
for app in \
  "/Applications/Slack.app" \
  "/Applications/Google Chrome.app" \
  "/Applications/ChatGPT.app" \
  "/Applications/Zed.app" \
  "/Applications/GitHub Desktop.app"; do
  if [ -d "$app" ]; then
    remove_quarantine_safe "$app"
    echo "✅ Removed quarantine from $app"
  fi
done

# Clean Dock and add preferred apps
say "🧼 Customizing Dock icons..."
if ! command -v dockutil &>/dev/null; then
  say "📦 Installing dockutil..."
  brew install dockutil
fi

dockutil --remove all --no-restart

apps_to_add=(
  "/Applications/Fantastical.app"
  "/Applications/Things3.app"
  "/Applications/Google Chrome.app"
  "/Applications/ChatGPT.app"
  "/Applications/Zed.app"
  "/Applications/GitHub Desktop.app"
  "/Applications/Messages.app"
  "/Applications/Sequel Ace.app"
  "/Applications/iTerm.app"
)

for app in "${apps_to_add[@]}"; do
  [[ -e "$app" ]] && dockutil --add "$app" --no-restart || say "⚠️  App not found: $app"
done

defaults write com.apple.dock desktop-view-settings -dict-add showStacks -bool true

### Create Screenshots and Projects folders
say "📁 Creating ~/Screenshots and ~/Projects folders..."
mkdir -p "$HOME/Screenshots"
mkdir -p "$HOME/Projects"

### Screenshot format + location
say "📸 Setting screenshot format and location..."
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"
killall SystemUIServer

### Add folders to the Dock
say "📌 Adding folders to the Dock..."

dockutil --add "$HOME/Projects"   --view grid --display folder --sort name --position end --no-restart
dockutil --add "$HOME/Screenshots" --view grid --display folder --sort dateadded --position end --no-restart
dockutil --add "$HOME/Downloads"  --view grid --display folder --sort dateadded --position end --no-restart

killall Dock

### Finder preferences
say "📂 Configuring Finder..."
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write NSGlobalDomain com.apple.springing.enabled -bool true
defaults write NSGlobalDomain com.apple.springing.delay -float 0
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder WarnOnEmptyTrash -bool false
defaults write com.apple.finder FXInfoPanesExpanded -dict General -bool true OpenWith -bool true
killall Finder

### Guest login
say "🔒 Disabling guest login..."
sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false
sudo dscl . -delete /Users/Guest &>/dev/null || true

### Trackpad & keyboard
say "🖱 Enabling tap-to-click and fast key repeat..."
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write -g ApplePressAndHoldEnabled -bool false
defaults write -g KeyRepeat -int 1
defaults write -g InitialKeyRepeat -int 10

### Bluetooth audio
say "🎧 Improving Bluetooth audio quality..."
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

### Safari settings
say "🌐 Configuring Safari..."
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true
defaults write com.apple.Safari ShowFavoritesBar -bool false
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

### Mail settings
say "✉️ Configuring Mail.app..."
defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false

# Enable ⌘ + Enter to send mail
/usr/libexec/PlistBuddy -c "Add :NSUserKeyEquivalents:Send string '@\\U21a9'" ~/Library/Preferences/com.apple.mail.plist || true

### iTerm: suppress quit prompt
say "💻 Configuring iTerm2..."
defaults write com.googlecode.iterm2 PromptOnQuit -bool false

bold "✅ macOS configuration complete!"
