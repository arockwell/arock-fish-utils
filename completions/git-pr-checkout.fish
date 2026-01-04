# Fish completions for git-pr-checkout

# Complete with open PR numbers
complete -c git-pr-checkout -f -a '(gh pr list --limit 20 --json number --jq ".[].number" 2>/dev/null)'

# Options
complete -c git-pr-checkout -s y -l yes -d "Auto-confirm worktree creation"
complete -c git-pr-checkout -s h -l help -d "Show help message"
