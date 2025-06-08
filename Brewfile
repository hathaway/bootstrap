tap 'caskroom/cask'
tap 'homebrew/bundle'
tap 'homebrew/core'
tap 'homebrew/services'
tap 'homebrew/versions'
tap 'homebrew/dupes'

# Packages
brew 'ack'
brew 'ag'
brew 'autoconf'
brew 'awscli'
# Install GNU core utilities (those that come with OS X are outdated)
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew 'coreutils'
# cmake is required to compile vim bundle YouCompleteMe
brew 'cmake'
brew 'dark-mode'
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed
brew 'findutils'
brew 'ffmpeg'
brew 'gawk'
brew 'gdbm'
brew 'gnupg'
# Install GNU `sed`, overwriting the built-in `sed`
# so we can do "sed -i 's/foo/bar/' file" instead of "sed -i '' 's/foo/bar/' file"
brew 'gnu-sed', args: ['with-default-names']
# better, more recent grep
brew 'homebrew/dupes/grep'
# https://github.com/jkbrzt/httpie
brew 'httpie'
brew 'imagemagick'
brew 'imagesnap'
# jq is a sort of JSON grep
brew 'jq'
brew 'lame'
brew 'mackup'
# Mac App Store CLI: https://github.com/mas-cli/mas
brew 'mas'
# Install some other useful utilities like `sponge`
brew 'moreutils'
brew 'mysql@5.5'
#brew 'mysql'
brew 'nmap'
brew 'node'
brew 'openssl'
brew 'pkg-config'
brew 'pv'
brew 'python'
brew 'readline'
brew 'rbenv'
brew 'reattach-to-user-namespace'
brew 'redis', restart_service: true
brew 'rename'
brew 'ruby-build'
# better/more recent version of screen
brew 'homebrew/dupes/screen'
brew 'screens-connect'
brew 'speedtest_cli'
brew 'sqlite'
brew 'ssh-copy-id'
brew 'swaks'
brew 'testssl'
brew 'tmux'
brew 'tree'
brew 'ttyrec'
# better, more recent vim
brew 'vim', args: ['with-override-system-vi']
brew 'watch'
brew 'webkit2png'
# Install wget with IRI support
brew 'wget', args: ['enable-iri']
brew 'x264'
brew 'xvid'
brew 'youtube-dl'
brew 'zsh'
brew 'zsh-syntax-highlighting'

# Applications
cask '1password'
# cask 'alfred'
# cask 'anvil'
# cask 'atom'
# cask 'chefdk'
cask 'cyberduck'
# cask 'dropbox'
# cask "font-hack-nerd-font"
cask 'firefox'
# cask 'flux'
cask 'github-desktop'
cask 'google-chrome'
# cask 'gpgtools'
cask 'istat-menus'
cask 'iterm2'
cask 'little-snitch'
cask 'micro-snitch'
# cask 'owncloud'
cask 'postman'
cask 'sequel-pro'
# cask 'sizeup'
# cask 'sketchup'
# cask 'skype'
cask 'slack'
# cask 'spectacle'
# cask 'the-unarchiver'
cask 'things'
# cask 'vagrant'
# cask 'vagrant-manager'
# cask 'virtualbox'
cask 'visual-studio-code'
cask 'vlc'

# Mac App Store applications
mas 'Xcode', id: 497799835
