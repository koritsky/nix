#!/usr/bin/env bash
set -e

# Install nix
if ! command -v nix &>/dev/null; then
  echo "Installing Nix..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  echo "Restart your shell, then re-run this script."
  exit 0
fi

# First home-manager activation
echo "Activating home-manager..."
nix run home-manager -- switch -b backup --flake ~/nix#server-linux
