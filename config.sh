#!/usr/bin/env bash

# CONSTANTS
declare -r DIR_USER_HOME=$(eval echo ~$USER)
declare -r DIR_USER_CONFIG=$DIR_USER_HOME/.config
declare -r DIR_SCRIPT=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

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

# ask for sudo permission
sudo -v
if [[ "$(sudo id -u)" -ne 0 ]]; then
  printf 'This script must be run with sudo\n'
fi

# change starship config to catppuccin
starship preset catppuccin-powerline -o ~/.config/starship.toml

# download zellij catppuccin theme
mkdir -p $DIR_USER_CONFIG/zellij/themes
curl https://raw.githubusercontent.com/catppuccin/zellij/refs/heads/main/catppuccin.kdl > $DIR_USER_CONFIG/zellij/themes/catppuccin.kdl

# stow all config files
stow --adopt --dir $DIR_SCRIPT/dotfiles --target $DIR_USER_HOME 
git restore .
