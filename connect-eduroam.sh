#!/usr/bin/env bash
set -euo pipefail

# --- Configuration (adjust for your university) ------------------------------

ANON_IDENTITY="eduroam@tu-darmstadt.de"
SERVER_DOMAIN="radius.hrz.tu-darmstadt.de"

# --- Paths -------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT_SOURCE="${SCRIPT_DIR}/config/network/eduroam-ca.pem"
CERT_TARGET="/var/lib/iwd/certs/eduroam-ca.pem"
IWD_DIR="/var/lib/iwd"
PROFILE="${IWD_DIR}/eduroam.8021x"

# --- Pre-checks --------------------------------------------------------------

if [[ "${EUID}" -ne 0 ]]; then
    echo "Run as root: sudo $0" >&2
    exit 1
fi

if [[ -f "$PROFILE" ]]; then
    echo "Profile already exists: $PROFILE" >&2
    echo "Delete it first to reconfigure." >&2
    exit 1
fi

if [[ ! -f "$CERT_SOURCE" && ! -f "$CERT_TARGET" ]]; then
    echo "Certificate missing: neither $CERT_SOURCE nor $CERT_TARGET found." >&2
    exit 1
fi

# --- Credentials -------------------------------------------------------------

read -rp "Eduroam username (e.g. user@uni.de): " EDU_USER
read -rsp "Eduroam password: " EDU_PASS
echo

# --- Setup -------------------------------------------------------------------

mkdir -p "$(dirname "$CERT_TARGET")" "$IWD_DIR"

if [[ -f "$CERT_SOURCE" ]]; then
    cp "$CERT_SOURCE" "$CERT_TARGET"
    echo "Certificate copied to $CERT_TARGET."
else
    echo "Certificate already present at $CERT_TARGET, skipping."
fi
chmod 644 "$CERT_TARGET"

umask 077
cat >"$PROFILE" <<EOF
[Security]
EAP-Method=PEAP
EAP-Identity=${EDU_USER}
EAP-PEAP-Phase2-Method=MSCHAPV2
EAP-PEAP-Phase2-Identity=${EDU_USER}
EAP-PEAP-Phase2-Password=${EDU_PASS}
EAP-PEAP-Anon-Identity=${ANON_IDENTITY}
EAP-PEAP-CACert=${CERT_TARGET}
EAP-ServerDomainMask=${SERVER_DOMAIN}
EOF

echo "iwd profile created: $PROFILE"
echo "Restart iwd if needed: systemctl restart iwd"
