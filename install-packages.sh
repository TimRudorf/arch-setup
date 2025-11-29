#!/usr/bin/env bash

# CONSTANTS
declare -r DIR_USER_HOME=$(eval echo ~$USER)

# default option values
OPTION_DEBUG=false

# check if debug is enabled
for parameter in "$@"
do
  case $parameter in

    -d | --debug)
      printf 'debug has been enabled\n'
      OPTION_DEBUG=true
      ;;

    *)
      printf "option '$parameter' is unknown\n"
      exit 1
      ;;
  esac
done

# packman packages to be installed
declare -r PACKAGES_PACMAN=(
  firefox
  yazi
  yazi
  yubikey-manager
  pam-u2f
  libfido2
  stow
  bat
  zellij
  bitwarden
  nextcloud-client
  )

# npm packages to be installed
declare -r PACKAGES_NPM=(
  @openai/codex
  )

# ask for sudo permission
sudo -v
if [[ "$(sudo id -u)" -ne 0 ]]; then
  printf 'This script must be run with sudo\n'
fi

# update pacman
printf '\n'
printf 'updating pacman ...\n'
if $OPTION_DEBUG; then
  sudo pacman -Syu
else
  sudo pacman -Syu > /dev/null 2>&1
fi

# install packages (pacman)
printf 'installing pacman packages\n'
for package in "${PACKAGES_PACMAN[@]}"
do
  printf "installing $package...\n"
  if $OPTION_DEBUG; then
    sudo pacman -S --noconfirm $package
  else
    sudo pacman -S --noconfirm $package > /dev/null 2>&1
  fi
done

# update npm
printf '\n'
printf 'updating npm...\n'
if $OPTION_DEBUG; then
  npm install -g npm@latest
else
  npm install -g npm@latest > /dev/null 2>&1
fi

# install packages (npm)
printf 'installing npm packages\n'
for package in "${PACKAGES_NPM[@]}"
do
  printf "installing $package...\n"
  if $OPTION_DEBUG; then
    npm install -g $package
  else
    npm install -g $package > /dev/null 2>&1
fi
done
