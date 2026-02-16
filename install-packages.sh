#!/usr/bin/env bash
set -euo pipefail

# --- Configuration -----------------------------------------------------------

NVM_VERSION="0.40.3"
NODE_VERSION="24"

PACKAGES_PACMAN=(
    # base
    git
    zsh
    iwd
    rsync
    less
    jq
    curl
    wget
    kitty
    fzf
    eza
    zoxide
    firefox
    stow
    bat
    zellij
    wl-clipboard
    ripgrep
    freerdp
    7zip
    power-profiles-daemon
    glow
    bluez
    # languages
    python
    python-pip
    # audio
    pavucontrol
    pactl
    pipewire
    pipewire-pulse
    wireplumber
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    # hyprland
    hyprland
    hyprlock
    hypridle
    hyprpaper
    rofi
    waybar
    dunst
    # tui
    btop
    lazygit
    lazysql
    neovim
    yazi
    impala
    bluetui
    # other
    bitwarden
    nextcloud-client
)

PACKAGES_NPM=(
    @openai/codex
)

# --- Options -----------------------------------------------------------------

VERBOSE=false

for arg in "$@"; do
    case "$arg" in
        -v|--verbose)
            VERBOSE=true
            ;;
        -h|--help)
            echo "Usage: $(basename "$0") [-v|--verbose] [-h|--help]"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            exit 1
            ;;
    esac
done

# --- Helper functions --------------------------------------------------------

log() { printf ':: %s\n' "$*"; }

run() {
    if "$VERBOSE"; then
        "$@"
    else
        "$@" >/dev/null 2>&1
    fi
}

install_yay() {
    if command -v yay >/dev/null 2>&1; then
        log "yay already installed"
        return
    fi

    local build_dir
    build_dir="$(mktemp -d)"
    trap 'rm -rf "$build_dir"' RETURN

    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git "$build_dir/yay"
    (cd "$build_dir/yay" && makepkg -si --noconfirm)
}

# --- Pre-checks --------------------------------------------------------------

if [[ "${EUID}" -eq 0 ]]; then
    echo "Do not run this script as root. It will ask for sudo when needed." >&2
    exit 1
fi

sudo -v

# --- Main --------------------------------------------------------------------

FAILED=()

log "Updating pacman..."
run sudo pacman -Syu --noconfirm

log "Installing yay..."
run install_yay

log "Installing pacman packages..."
for package in "${PACKAGES_PACMAN[@]}"; do
    log "  $package"
    if ! run yay -S --needed --noconfirm "$package"; then
        FAILED+=("$package")
    fi
done

log "Installing NVM and Node.js ${NODE_VERSION}..."
run curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash
export NVM_DIR="${HOME}/.nvm"
# shellcheck source=/dev/null
. "${NVM_DIR}/nvm.sh"
run nvm install "$NODE_VERSION"

log "Installing npm packages..."
for package in "${PACKAGES_NPM[@]}"; do
    log "  $package"
    if ! run npm install -g "$package"; then
        FAILED+=("$package")
    fi
done

# --- Summary -----------------------------------------------------------------

echo
if [[ ${#FAILED[@]} -gt 0 ]]; then
    log "Finished with ${#FAILED[@]} failed package(s):"
    printf '   - %s\n' "${FAILED[@]}"
    exit 1
else
    log "All packages installed successfully."
fi
