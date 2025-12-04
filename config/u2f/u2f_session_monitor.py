#!/usr/bin/env python3
"""
Locks the current session when a YubiKey is unplugged, unless the Super key
is held during removal. Run via the systemd --user service installed by
../u2f_session.sh.
"""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path
from typing import Dict, Iterable

LOCK_COMMAND = ["loginctl", "lock-session"]
YUBIKEY_VENDOR_IDS = {"1050"}
YUBIKEY_PRODUCT_IDS = {
    "0010",
    "0110",
    "0114",
    "0118",
    "0120",
    "0121",
    "0200",
    "0401",
    "0402",
    "0403",
    "0404",
    "0405",
    "0406",
    "0407",
    "0408",
    "0410",
    "0413",
    "0420",
    "0421",
    "0423",
    "0441",
    "1050",
    "1120",
    "1160",
}


def _value_matches(value: str | None, options: Iterable[str]) -> bool:
    if value is None:
        return False
    def norm(val: str) -> str:
        stripped = val.strip().upper().lstrip("0")
        return stripped if stripped else "0"

    value_norm = norm(value)
    return any(value_norm == norm(opt) for opt in options)


def _super_pressed() -> bool:
    from evdev import InputDevice, ecodes

    meta = {ecodes.KEY_LEFTMETA, ecodes.KEY_RIGHTMETA}
    seen_paths = []
    for path in Path("/dev/input").glob("event*"):
        seen_paths.append(str(path))
        try:
            dev = InputDevice(str(path))
            if set(dev.active_keys()) & meta:
                sys.stderr.write(f"[u2f_session] super check: meta active on {path}\n")
                sys.stderr.flush()
                return True
        except Exception as exc:  # read errors are possible; ignore but log once
            sys.stderr.write(f"[u2f_session] super check: cannot read {path}: {exc}\n")
            sys.stderr.flush()
            continue
    sys.stderr.write(f"[u2f_session] super check: no meta active; inspected={','.join(seen_paths)}\n")
    sys.stderr.flush()
    return False


def _lock_if_needed() -> None:
    if _super_pressed():
        sys.stderr.write("[u2f_session] YubiKey removed but Super held; skip locking.\n")
        sys.stderr.flush()
        return

    sys.stderr.write("[u2f_session] YubiKey removed; locking session.\n")
    sys.stderr.flush()
    subprocess.run(LOCK_COMMAND, check=False)


def _monitor() -> None:
    # Use udevadm to stream events; easier than adding pyudev dependency.
    proc = subprocess.Popen(
        ["udevadm", "monitor", "--udev", "--subsystem-match=usb", "--property", "--environment"],
        stdout=subprocess.PIPE,
        text=True,
        bufsize=1,
    )
    assert proc.stdout is not None

    current: Dict[str, str] = {}

    for raw_line in proc.stdout:
        line = raw_line.strip()
        if not line or line.startswith(("UDEV", "KERNEL")):
            action = current.get("ACTION")
            vendor = current.get("ID_VENDOR_ID")
            product = current.get("ID_MODEL_ID")
            devtype = current.get("DEVTYPE")

            # PRODUCT key is formatted as vendor/product/revision (hex); use as fallback.
            product_field = current.get("PRODUCT")
            if product_field and "/" in product_field:
                parts = product_field.split("/")
                if len(parts) >= 2:
                    vendor = vendor or parts[0]
                    product = product or parts[1]

            if action == "remove" and (devtype is None or devtype == "usb_device"):
                matched_vendor = _value_matches(vendor, YUBIKEY_VENDOR_IDS)
                matched_product = _value_matches(product, YUBIKEY_PRODUCT_IDS)
                sys.stderr.write(
                    f"[u2f_session] remove event: vendor={vendor} product={product} "
                    f"product_field={product_field} matched_vendor={matched_vendor} matched_product={matched_product}\n"
                )
                sys.stderr.flush()
                if matched_vendor and matched_product:
                    _lock_if_needed()
            current.clear()
            continue

        if "=" in line:
            key, value = line.split("=", 1)
            current[key] = value


def main() -> int:
    # Ensure log output is visible even when launched by systemd.
    os.environ.setdefault("PYTHONUNBUFFERED", "1")
    try:
        _monitor()
    except KeyboardInterrupt:
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
