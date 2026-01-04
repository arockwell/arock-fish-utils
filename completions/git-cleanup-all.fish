# Fish completions for git-cleanup-all

# Options
complete -c git-cleanup-all -s y -l yes -d "Auto-delete merged items without prompting"
complete -c git-cleanup-all -l skip-worktrees -d "Skip worktree cleanup"
complete -c git-cleanup-all -l skip-branches -d "Skip branch cleanup"
complete -c git-cleanup-all -s h -l help -d "Show help message"
