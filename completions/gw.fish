# Fish completions for gw (git worktree switcher)

# Disable file completions
complete -c gw -f

# Complete with branch names from worktrees
complete -c gw -a '(git worktree list --porcelain 2>/dev/null | grep "^branch " | sed "s/branch refs\/heads\///")'

# Help option
complete -c gw -s h -l help -d "Show help message"
