function gitac --wraps='git add . && git commit -m' --description 'Stage all and commit'
    if test (count $argv) -eq 0
        echo "Usage: gitac <commit message>"
        return 1
    end
    git add . && git commit -m $argv
end
