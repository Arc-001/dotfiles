#!/bin/bash
# niri-fix-filepicker.sh
# Fixes xdg-desktop-portal file picker on Fedora + niri
# Usage: bash niri-fix-filepicker.sh

set -e

echo "==> Installing xdg-desktop-portal and gtk backend..."
sudo dnf install -y xdg-desktop-portal xdg-desktop-portal-gtk

echo "==> Writing portals.conf..."
mkdir -p ~/.config/xdg-desktop-portal
cat >~/.config/xdg-desktop-portal/portals.conf <<EOF
[preferred]
default=gtk
org.freedesktop.impl.portal.FileChooser=gtk
EOF

echo "==> Writing systemd user service..."
mkdir -p ~/.config/systemd/user
cat >~/.config/systemd/user/niri-session-env.service <<EOF
[Unit]
Description=Set niri session environment for portal
Before=xdg-desktop-portal.service

[Service]
Type=oneshot
ExecStart=/usr/bin/dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=niri

[Install]
WantedBy=default.target
EOF

echo "==> Enabling service..."
systemctl --user daemon-reload
systemctl --user enable niri-session-env.service

echo "==> Restarting portal..."
systemctl --user restart xdg-desktop-portal.service || true
systemctl --user restart xdg-desktop-portal-gtk.service || true

echo ""
echo "Done! Log out and back in (or reboot) for the session service to take effect."
