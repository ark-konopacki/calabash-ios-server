#!/usr/bin/env bash

function info {
  echo "$(tput setaf 2)INFO: $1$(tput sgr0)"
}

function error {
  echo "$(tput setaf 1)ERROR: $1$(tput sgr0)"
}

function banner {
  echo ""
  echo "$(tput setaf 5)######## $1 #######$(tput sgr0)"
  echo ""
}

make clean

banner "Install Code Signing Keychain"
bin/ci/jenkins/install-keychain.sh

bundle update

# Make libraries
make framework
make frank
bin/ci/jenkins/make-dylibs.sh

bin/ci/jenkins/make-ipa.sh
bundle exec bin/test/test-cloud.rb

# Restart CoreSimulator processes
bundle update
bundle exec run-loop simctl manage-processes

banner "Run Tests"
bundle exec bin/test/xctest.rb
bundle exec bin/test/cucumber.rb

banner "Test iPhone 6+ touch coordinates"
bundle exec bin/test/acquaint.rb

