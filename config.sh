#!/usr/bin/env bash

# CONSTANTS
declare -r DIR_USER_HOME=$(eval echo ~$USER)
declare -r DIR_USER_CONFIG=$DIR_USER_HOME/.config
declare -r DIR_SCRIPT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
declare -r ZSH_CUSTOM=$DIR_USER_HOME/.oh-my-zsh/custom
declare -r DIR_FIREFOX_PROFILES=$DIR_USER_HOME/.mozilla/firefox
declare -r STR_FIREFOX_PROFILE_SUBSTRING='default-release'

# default option values
OPTION_DEBUG=false

# check if debug is enabled
for parameter in "$@"; do
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

# stow all config files
cd $DIR_SCRIPT/dotfiles
stow --target $DIR_USER_HOME *
cd $DIR_SCRIPT

# zsh als Standardshell
sudo chsh -s $(which zsh) $USER

# Fonts runterladen
yay -S --noconfirm ttf-meslo-nerd-font-powerlevel10k

# oh-my-zsh installieren
if [[ ! -d $ZSH_CUSTOM ]]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) -y"
fi

# oh-my-zsh plugins

plugins=(
  "https://github.com/zsh-users/zsh-autosuggestions;$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  "https://github.com/zsh-users/zsh-syntax-highlighting.git;$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  "--depth=1 https://github.com/romkatv/powerlevel10k.git;$ZSH_CUSTOM/themes/powerlevel10k"
)

for plugin in "${plugins[@]}"; do
  IFS=';' read -r url dir <<<"$plugin"
  if [ -d "$dir/.git" ] || [ -d "$dir" ]; then
    echo "Überspringe clone, existiert schon: $dir"
  else
    echo "Cloning $url -> $dir"
    git clone "$url" "$dir"
  fi
done

# iwd aktivieren
sudo systemctl enable iwd
sudo systemctl start iwd

# Firefox config syncen
printf 'Firefox Konfiguration setzen\n'
declare -r DIR_FIREFOX_ACTIVE_PROFILE=$(find $DIR_FIREFOX_PROFILES -type d -name "*.$STR_FIREFOX_PROFILE_SUBSTRING" -print -quit)
rsync -avhP $DIR_SCRIPT/config/firefox/* $DIR_FIREFOX_ACTIVE_PROFILE

# install u2f files
sudo install -b -m 644 $DIR_SCRIPT/config/u2f/u2f_mapping /etc/u2f_mapping
sudo install -b -m 644 $DIR_SCRIPT/config/u2f/pam.d/sudo /etc/pam.d/sudo
sudo install -b -m 644 $DIR_SCRIPT/config/u2f/pam.d/login /etc/pam.d/login
