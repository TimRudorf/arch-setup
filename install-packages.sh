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
  # base -------------------
  git
  iwd
  rsync
  less
  jq
  curl
  wget
  ghostty
  btop
  firefox
  stow
  bat
  zellij
  wl-clipboard
  # languages --------------
  nodejs
  npm
  python
  # hyperland --------------
  hyprland
  hyprlock
  hypridle
  walker
  waybar
  # tui --------------------
  btop
  lazygit
  neovim
  yazi
  impala
  bluetui
  # u2f/passkey ------------
  yubikey-manager
  pam-u2f
  libfido2
  # other ------------------
  bitwarden
  nextcloud-client
  )

# npm packages to be installed
declare -r PACKAGES_NPM=(
  @openai/codex
  )

# Hilfsfunktion: Ausgabe je nach Debug Modus
function run_debug() {
  if $OPTION_DEBUG; then
    $@
  else
    $@ > /dev/null 2>&1
  fi
}

# yay installieren
function install_yay() {
  if command -v yay > /dev/null 2>&1; then
    printf 'yay already installed\n'
    return
  fi

  
  sudo pacman -S --needed --noconfirm git base-devel
  git clone https://aur.archlinux.org/yay.git $DIR_USER_HOME
  cd $DIR_USER_HOME/yay
  makepkg -si
  cd $DIR_USER_HOME
}

# pacman package installieren
function install_pacman_package() {
  yay -S --noconfirm $1
}

# ask for sudo permission
sudo -v
if [[ "$(sudo id -u)" -ne 0 ]]; then
  printf 'This script must be run with sudo\n'
fi

# update pacman
printf '\n'
printf 'updating pacman ...\n'
run_debug sudo pacman -Syu --noconfirm

# install yay
printf 'installing yay...\n'
run_debug install_yay

# install packages (pacman)
printf 'installing pacman packages\n'
for package in "${PACKAGES_PACMAN[@]}"
do
  printf "installing $package...\n"
  run_debug install_pacman_package $package
done

# update npm
printf '\n'
printf 'updating npm...\n'
run_debug sudo npm install -g npm@latest

# install packages (npm)
printf 'installing npm packages\n'
for package in "${PACKAGES_NPM[@]}"
do
  printf "installing $package...\n"
  run_debug sudo npm install -g $package
done
