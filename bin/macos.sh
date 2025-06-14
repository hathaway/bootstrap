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

# Set Finder favorites
say "📁 Setting Finder favorites..."
FAVORITES=(
  "com.apple.LSSharedFileList.FavoriteItems:0:/System/Library/CoreServices/Finder.app/Contents/Applications/AirDrop.app"
  "com.apple.LSSharedFileList.FavoriteItems:1:/System/Library/CoreServices/Finder.app/Contents/Applications/Recents.app"
  "com.apple.LSSharedFileList.FavoriteItems:2:/Applications"
  "com.apple.LSSharedFileList.FavoriteItems:3:~/Desktop"
  "com.apple.LSSharedFileList.FavoriteItems:4:~/Documents"
  "com.apple.LSSharedFileList.FavoriteItems:5:~/Downloads"
  "com.apple.LSSharedFileList.FavoriteItems:6:~/Projects"
  "com.apple.LSSharedFileList.FavoriteItems:7:~/Screenshots"
)

for favorite in "${FAVORITES[@]}"; do
  IFS=":" read -r key index path <<< "$favorite"
  defaults write com.apple.finder "$key" -array-add "<dict><key>Index</key><integer>$index</integer><key>URL</key><string>file://$path</string></dict>"
done
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar -bool true
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

### Safari settings
say "🌐 Configuring Safari..."
plutil -replace ShowFullURLInSmartSearchField -bool true ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari.plist
plutil -replace ShowFavoritesBar -bool false ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari.plist
plutil -replace IncludeDevelopMenu -bool true ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari.plist
plutil -replace WebKitDeveloperExtrasEnabledPreferenceKey -bool true ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari.plist
plutil -replace com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari.plist
plutil -replace WebKitDeveloperExtras -bool true ~/Library/Preferences/.GlobalPreferences.plist

### Mail settings
say "✉️ Configuring Mail.app..."
defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false

# Enable ⌘ + Enter to send mail
/usr/libexec/PlistBuddy -c "Add :NSUserKeyEquivalents:Send string '@\\U21a9'" ~/Library/Preferences/com.apple.mail.plist || true

### iTerm: suppress quit prompt
say "💻 Configuring iTerm2..."
defaults write com.googlecode.iterm2 PromptOnQuit -bool false

bold "✅ macOS configuration complete! You may need to restart your computer for some changes to take effect."
