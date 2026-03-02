function gitac --wraps='git add . && git commit -m ' --description 'alias gitac git add . && git commit -m '
  git add . && git commit -m  $argv
        
end
