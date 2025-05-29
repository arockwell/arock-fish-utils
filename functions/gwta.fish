function gwta --description 'make branch and switch to the worktree'
    git branch $argv[1]
    git worktree add ../$argv[1] $argv[1]
    cd ../$argv[1]
end
