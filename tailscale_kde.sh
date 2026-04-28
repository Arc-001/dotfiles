#!/bin/bash
# Tailscale setup script for Fedora
# Usage: chmod +x tailscale-setup.sh && sudo ./tailscale-setup.sh

set -e

echo ">>> Adding Tailscale repo..."
dnf config-manager --add-repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo -y

echo ">>> Installing Tailscale..."
dnf install tailscale -y

echo ">>> Enabling and starting tailscaled..."
systemctl enable --now tailscaled

echo ">>> Authenticating (a URL will appear — open it in your browser)..."
tailscale up

echo ""
echo ">>> Done! Your devices:"
tailscale status
