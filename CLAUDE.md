# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Arch Linux setup scripts for bootstrapping a fresh install. Dotfiles are managed in a separate repository: [TimRudorf/dotfiles](https://github.com/TimRudorf/dotfiles).

## Repository Structure

- `install-packages.sh` — Installs yay (AUR helper), pacman/npm packages. Run with `-v`/`--verbose` for verbose output.
- `connect-eduroam.sh` — Configures iwd for eduroam WiFi. Requires root. University-specific values are configured as variables at the top.
- `config/network/` — Network certificates (eduroam CA)

## Key Conventions

- Scripts should be generic and not assume specific hardware
- Language: English for code/comments
- Scripts use `set -euo pipefail` and proper error handling

## Git Workflow

- `main` is protected — no direct pushes
- Always work on feature branches and merge via PR
