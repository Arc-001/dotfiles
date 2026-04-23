if status is-interactive
    starship init fish | source
    zoxide init fish | source

    function open; nautilus $argv >/dev/null 2>&1 &; disown; end

    abbr -a vi nvim
    alias ls "eza --icons --color=auto"
    alias la "eza -la --icons --color=auto"
    alias ll "eza -l -g --icons --color=auto"
    alias tree "eza --tree --icons --color=auto"
    set -gx EDITOR nvim
end
