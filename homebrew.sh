#!/usr/bin/env bash

source ./lib_sh/echos.sh
source ./lib_sh/requirers.sh

#####
# install homebrew (CLI Packages)
#####
bot "I'm going to install homebrew and all of your packages and apps in the Brewfile."

running "checking homebrew install"
brew_bin=$(which brew) 2>&1 > /dev/null
if [[ $? != 0 ]]; then
  action "installing homebrew"
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    if [[ $? != 0 ]]; then
      error "unable to install homebrew, script $0 abort!"
      exit 2
  fi
else
  ok
  # Make sure we’re using the latest Homebrew
  running "updating homebrew"
  brew update
  ok
  bot "before installing brew packages, we can upgrade any outdated packages."
  read -r -p "run brew upgrade? [y|N] " response
  if [[ $response =~ ^(y|yes|Y) ]];then
      # Upgrade any already-installed formulae
      action "upgrade brew packages..."
      brew upgrade
      ok "brews updated..."
  else
      ok "skipped brew package upgrades.";
  fi
fi

# Brewfile
running "bundling the Brewfile"
brew bundle
ok

# Cleanup homebrew
running "cleanup homebrew"
running "cleanup homebrew"
brew cleanup > /dev/null 2>&1
ok

bot "Woot! All done."
