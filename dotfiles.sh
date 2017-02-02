#!/usr/bin/env bash

source ./lib_sh/echos.sh
source ./lib_sh/requirers.sh

bot "I'm going to restore all of your dotfiles using mackup."
# Restore the dotfiles from this GitHub repo using mackup

action "copying the mackup configuration file..."
cp -f ~/.dotfiles/.mackup.cfg ~/.mackup.cfg
ok "copied."

action "restoring mackup file..."
mackup restore
ok "mackup restore complete."

bot "Woot! All done."
