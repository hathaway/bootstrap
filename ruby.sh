#!/usr/bin/env bash

source ./lib_sh/echos.sh
source ./lib_sh/requirers.sh

bot "I'm going to configure your ruby environment with rbenv."
# TODO: Install and configure the ruby environment

# ruby
running "Installing ruby 1.9.3-p551"
rbenv install 1.9.3-p551;ok

running "Installing bundler"
rbenv global 2.3.1
gem install bundler;ok

running "Installing ruby 2.3.1"
rbenv install 2.3.1;ok

running "Setting 2.3.1 as global ruby"
rbenv global 2.3.1;ok

running "Installing bundler"
gem install bundler;ok

bot "All done."
