# Fish completions for gwp (git worktree path)

# Disable file completions
complete -c gwp -f

# Complete with branch names from worktrees
complete -c gwp -a '(git worktree list --porcelain 2>/dev/null | grep "^branch " | sed "s/branch refs\/heads\///")'

# Options
complete -c gwp -s e -l exact -d "Require exact branch name match"
complete -c gwp -s h -l help -d "Show help message"
