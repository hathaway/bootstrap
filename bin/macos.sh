#!/usr/bin/env bash
set -euo pipefail

echo "⚙️  Configuring macOS system preferences..."

### Ask for sudo up front
require_sudo_session() {
  echo "🔐 Requesting sudo access..."
  sudo -v
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}
require_sudo_session

### Prompt for computer name / hostname
read -r -p "📛 Enter a name for your computer: " computer_name
sudo scutil --set ComputerName "$computer_name"
sudo scutil --set HostName "$computer_name"
sudo scutil --set LocalHostName "$computer_name"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$computer_name"

### Dock settings
echo "🔧 Configuring Dock..."
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 48
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock showAppExposeGestureEnabled -bool true

# Clean Dock and add preferred apps
echo "🧼 Customizing Dock icons..."
if ! command -v dockutil &>/dev/null; then
  echo "📦 Installing dockutil..."
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
  [[ -e "$app" ]] && dockutil --add "$app" --no-restart || echo "⚠️  App not found: $app"
done

defaults write com.apple.dock desktop-view-settings -dict-add showStacks -bool true

### Create Screenshots and Projects folders
echo "📁 Creating ~/Screenshots and ~/Projects folders..."
mkdir -p "$HOME/Screenshots"
mkdir -p "$HOME/Projects"

### Screenshot format + location
echo "📸 Setting screenshot format and location..."
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"
killall SystemUIServer

### Add folders to the Dock
echo "📌 Adding folders to the Dock..."

dockutil --add "$HOME/Projects"   --view grid --display folder --sort name --position end --no-restart
dockutil --add "$HOME/Screenshots" --view grid --display folder --sort dateadded --position end --no-restart
dockutil --add "$HOME/Downloads"  --view grid --display folder --sort dateadded --position end --no-restart

killall Dock

### Finder preferences
echo "📂 Configuring Finder..."
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
echo "🔒 Disabling guest login..."
sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false
sudo dscl . -delete /Users/Guest &>/dev/null || true

### Trackpad & keyboard
echo "🖱 Enabling tap-to-click and fast key repeat..."
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write -g ApplePressAndHoldEnabled -bool false
defaults write -g KeyRepeat -int 1
defaults write -g InitialKeyRepeat -int 10

### Bluetooth audio
echo "🎧 Improving Bluetooth audio quality..."
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

### Safari settings
echo "🌐 Configuring Safari..."
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true
defaults write com.apple.Safari ShowFavoritesBar -bool false
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

### Mail settings
echo "✉️ Configuring Mail.app..."
defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false

# Enable ⌘ + Enter to send mail
/usr/libexec/PlistBuddy -c "Add :NSUserKeyEquivalents:Send string '@\\U21a9'" ~/Library/Preferences/com.apple.mail.plist || true

### iTerm: suppress quit prompt
echo "💻 Configuring iTerm2..."
defaults write com.googlecode.iterm2 PromptOnQuit -bool false

echo "✅ macOS configuration complete!"