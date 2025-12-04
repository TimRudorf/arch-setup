#!/usr/bin/env bash
set -euo pipefail

DIR_REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
SRC_MONITOR="$DIR_REPO/config/u2f/u2f_session_monitor.py"
SRC_SERVICE="$DIR_REPO/config/u2f/u2f-session.service"
TARGET_LIB="$HOME/.local/lib/u2f-session"
TARGET_SERVICE_DIR="$HOME/.config/systemd/user"
TARGET_MONITOR="$TARGET_LIB/u2f_session_monitor.py"
SERVICE_NAME="u2f-session.service"

main() {
  # Sudo Rechte
  sudo -v

  # In Input Gruppe aufnehmen
  sudo usermod -aG input "$USER"

  mkdir -p "$TARGET_LIB" "$TARGET_SERVICE_DIR"

  install -m 755 "$SRC_MONITOR" "$TARGET_MONITOR"
  install -m 644 "$SRC_SERVICE" "$TARGET_SERVICE_DIR/$SERVICE_NAME"

  systemctl --user daemon-reload
  systemctl --user enable --now "$SERVICE_NAME"

  echo "u2f session monitor installed and started (systemd --user service: $SERVICE_NAME)"
}

main "$@"
