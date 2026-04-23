#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$HOME/.config"

link() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"

    if [[ -L "$dst" ]]; then
        if [[ "$(readlink "$dst")" == "$src" ]]; then
            echo "ok     $dst"
            return
        fi
        rm "$dst"
    elif [[ -e "$dst" ]]; then
        local bak="${dst}.bak.$(date +%Y%m%d%H%M%S)"
        mv "$dst" "$bak"
        echo "backup $dst -> $bak"
    fi

    ln -s "$src" "$dst"
    echo "linked $dst"
}

link "$DOTFILES/fishConf"                   "$CONFIG/fish"
link "$DOTFILES/kitty"                      "$CONFIG/kitty"
link "$DOTFILES/neoVim"                     "$CONFIG/nvim"
link "$DOTFILES/niriConf/config.kdl"        "$CONFIG/niri/config.kdl"
link "$DOTFILES/starshipConf/starship.toml" "$CONFIG/starship.toml"
link "$DOTFILES/waybarConf"                 "$CONFIG/waybar"

chmod +x "$DOTFILES/waybarConf/scripts/"*.sh
chmod +x "$DOTFILES/sweep.sh"
chmod +x "$DOTFILES/revert.sh"

echo "done"
