if status is-interactive
    # Commands to run in interactive sessions can go here
    starship init fish | source
    alias open="nautilus \$argv >/dev/null 2>&1 &"
    zoxide init fish | source

    alias vi="nvim"
    alias ls="eza --icons --color=auto"
    alias ll="eza -l -g --icons --color=auto"
    alias tree="eza --tree --icons --color=auto"
    export EDITOR=nvim
end
