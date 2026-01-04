# 🔧 Configuration for arock-fish-utils plugin
# This runs when Fish shell starts

# 📌 Set plugin version
set -g AROCK_FISH_UTILS_VERSION 1.2.0

# 🎨 Git workflow abbreviations
# Quick shortcuts for common git-workflow commands

# Worktree management
abbr -a gws --set-cursor "git-worktree-status" # Quick worktree status
abbr -a gwc --set-cursor "git-worktree-cleanup" # Clean up worktrees
abbr -a gwci --set-cursor "git-worktree-cleanup --interactive" # Interactive cleanup

# Repository sync and health
abbr -a gsa --set-cursor "git-sync-all" # Sync all worktrees
abbr -a gca --set-cursor "git-cleanup-all" # Full cleanup
abbr -a grh --set-cursor "git-repo-health" # Repository health

# Branch management
abbr -a gbc --set-cursor "git-branch-cleanup" # Clean up branches
abbr -a gbci --set-cursor "git-branch-cleanup --interactive" # Interactive branch cleanup

# PR workflow
abbr -a gpc --set-cursor "git-pr-checkout %" # Checkout PR (% = cursor position)

# Dashboard
abbr -a gd --set-cursor "git-dashboard" # Interactive dashboard
