#!/usr/bin/env bash
set -euo pipefail

# Utility functions
say()   { echo -e "🔹 $1"; }
bold()  { echo -e "\033[1m$1\033[0m"; }
prompt() {
  read -r -p "❓ $1 [y/N] " response
  [[ "$response" =~ ^[Yy](es)?$ ]]
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

### Disable app quarantine warning
echo "🚫 Disabling 'Are you sure you want to open this?' prompts..."
defaults write com.apple.LaunchServices LSQuarantine -bool false

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
  "/System/Applications/Messages.app"
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

### Hot Corners
say "🖱 Configuring Hot Corners..."
# Top right: Show Notification Center
defaults write com.apple.dock wvous-tr-corner -int 12
defaults write com.apple.dock wvous-tr-modifier -int 0
# Bottom right: Show Desktop
defaults write com.apple.dock wvous-br-corner -int 4
defaults write com.apple.dock wvous-br-modifier -int 0
# Top left: App Exposé
defaults write com.apple.dock wvous-tl-corner -int 2
defaults write com.apple.dock wvous-tl-modifier -int 0

### Finder preferences
say "📂 Configuring Finder..."
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

defaults write com.apple.finder ShowStatusBar -bool false
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder NewWindowTarget -string "PfDe"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Desktop/"
defaults write com.apple.finder _FXShowPosixPathInTitle -bool false
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

### iTerm: suppress quit prompt
say "💻 Configuring iTerm2..."
defaults write com.googlecode.iterm2 PromptOnQuit -bool false

bold "✅ macOS configuration complete! You may need to restart your computer for some changes to take effect."
