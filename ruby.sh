#!/usr/bin/env bash

# TODO: Install and configure the ruby environment

# ruby
rbenv install 1.9.3-p551
rbenv install 2.3.1
rbenv global 2.3.1

rbenv shell 1.9.3-p551
gem install bundler
