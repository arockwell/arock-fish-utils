# 📚 arock-fish-utils Documentation

Complete documentation for all Git workflow utilities.

## 📖 Table of Contents

- [Quick Start](#quick-start)
- [Worktree Management](#worktree-management)
- [Branch Management](#branch-management)
- [Repository Health](#repository-health)
- [PR Review Workflow](#pr-review-workflow)
- [Tab Completions](#tab-completions)
- [Advanced Usage](#advanced-usage)

## Quick Start

### Installation
```fish
fisher install arockwell/arock-fish-utils
```

### Essential Commands
```fish
gw                      # Switch worktrees with fuzzy search
git-worktree-status     # Quick status overview
git-pr-checkout 123     # Checkout PR for review
git-sync-all            # Sync all worktrees
git-cleanup-all         # Full repository cleanup
```

## Worktree Management

### `gw` - Worktree Switcher

Fast fuzzy search to switch between worktrees or create new ones.

**Usage:**
```fish
gw                  # Show fuzzy search menu
gw feature          # Search with initial query
gw <TAB>            # Tab complete with branch names
```

**Features:**
- Fuzzy search with fzf
- Create new worktrees interactively
- Handles local, remote, and new branches
- Tab completion for branch names

**Worktree Path Convention:**
```
/path/to/repos/worktrees/repo-name-branch-name
```

---

### `git-worktree-status` - Quick Status Overview

One-line status for all worktrees with emoji indicators.

**Usage:**
```fish
git-worktree-status              # Show worktrees with changes
git-worktree-status --all        # Show all worktrees
git-worktree-status --compact    # Emoji-only mode
```

**Status Indicators:**
- ✅ Clean and up-to-date
- 📝 Uncommitted changes
- 📤 Unpushed commits
- 📥 Behind remote
- ⚠️  Diverged from remote
- 📍 No remote tracking
- 💥 Broken worktree

**Example Output:**
```
Git Worktree Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝  feature/new-auth              3 changes
📤  fix/bug-123                   ↑2
📥  main                          ↓1
⚠️   hotfix/critical              ↑1 ↓2
```

**Use Cases:**
- Daily status check
- Add to tmux/zellij status line
- Quick repo overview before cleanup

---

### `git-worktree-cleanup` - Clean Up Old Worktrees

Analyze and clean up old/merged worktrees.

**Usage:**
```fish
git-worktree-cleanup                    # Interactive analysis
git-worktree-cleanup --interactive      # Review each worktree
git-worktree-cleanup --delete-merged    # Auto-delete merged
```

**Analysis Categories:**
- **Safe to delete:** Merged to main, remote deleted
- **Review needed:** Not merged, no remote
- **Keep:** Currently in use (in a worktree)

**Interactive Mode:**
Shows for each worktree:
- Branch name and path
- Merge status
- Unmerged commit count
- Last commit date
- PR number (if available)
- Uncommitted changes

**Actions:**
- [d] Delete worktree
- [v] View diff with main
- [k] Keep (skip)
- [q] Quit

---

## Branch Management

### `git-branch-cleanup` - Clean Up Local Branches

Clean up local branches that are no longer needed.

**Usage:**
```fish
git-branch-cleanup                    # Show analysis
git-branch-cleanup --interactive      # Review each branch
git-branch-cleanup --delete-merged    # Auto-delete merged
```

**Branch Categories:**
- **Safe to keep:** In a worktree
- **Safe to delete:** Merged to main
- **Orphaned:** Not in any worktree, not merged
- **No remote:** No remote tracking

**Interactive Mode for Orphaned Branches:**
- [d] Delete branch
- [v] View commits
- [w] Create worktree for this branch
- [k] Keep (skip)
- [q] Quit

---

## Repository Health

### `git-repo-health` - Health Dashboard

Comprehensive repository health dashboard.

**Usage:**
```fish
git-repo-health
```

**Shows:**

**📊 Disk Usage**
- Main repository size
- Worktree sizes
- .git directory size

**🌿 Branches**
- Total, local, remote counts
- Merged branches (deletable)
- Stale branches (90+ days old)

**🔧 Worktrees**
- Total worktree count
- Uncommitted work per worktree
- Status indicators

**⬆️ Unpushed Commits**
- Branches with unpushed commits
- Commit counts per branch

**🎯 Recommendations**
- Cleanup suggestions
- Next actions

---

### `git-sync-all` - Sync All Worktrees

Sync all worktrees with their remote branches.

**Usage:**
```fish
git-sync-all                    # Fetch and pull
git-sync-all --fetch-only       # Fetch only, no pull
git-sync-all --all              # Show clean worktrees too
```

**Process:**
1. Fetches all remotes
2. Checks each worktree's status
3. Auto-pulls clean worktrees that are behind
4. Reports issues (dirty, diverged, no remote)

**Summary:**
- ✅ Up to date
- 📤 Ahead of remote
- 📥 Behind (pulled)
- ⚠️  Diverged (needs manual merge)
- ⚠️  Dirty (needs commit/stash)
- 📍 No remote tracking

---

### `git-cleanup-all` - Complete Repository Cleanup

Run all cleanup utilities in sequence.

**Usage:**
```fish
git-cleanup-all                  # Interactive cleanup
git-cleanup-all --yes            # Auto-delete merged items
git-cleanup-all --skip-worktrees # Skip worktree cleanup
git-cleanup-all --skip-branches  # Skip branch cleanup
```

**Steps:**
1. **Sync worktrees** - Fetch and update all worktrees
2. **Clean worktrees** - Remove merged/old worktrees
3. **Clean branches** - Remove merged branches
4. **Prune references** - Clean broken worktree/remote refs
5. **Health check** - Show final repository status

**Recommended Schedule:**
- Weekly: `git-cleanup-all`
- After major merges: `git-cleanup-all --yes`
- Before releases: `git-repo-health`

---

## PR Review Workflow

### `git-pr-checkout` - Checkout PRs as Worktrees

Quickly checkout GitHub PRs as worktrees for review.

**Prerequisites:**
- `gh` (GitHub CLI) must be installed
- Authenticated with `gh auth login`

**Usage:**
```fish
git-pr-checkout              # List and select PR
git-pr-checkout 123          # Checkout PR #123
git-pr-checkout 123 --yes    # Auto-confirm
git-pr-checkout <TAB>        # Tab complete with PR numbers
```

**Workflow:**
1. Shows PR title, branch, repository
2. Creates worktree at `worktrees/repo-pr-123`
3. Fetches PR branch using `gh`
4. Optionally switches to worktree

**Example:**
```fish
# Review PR #456
git-pr-checkout 456

# Make changes, test
cd /path/to/worktrees/emdx-pr-456
# ... test, review, comment ...

# Clean up when done
git-worktree-cleanup
```

---

## Tab Completions

All utilities include Fish shell tab completions.

### Completion Types

**Dynamic Completions:**
- `gw <TAB>` → Branch names from worktrees
- `git-pr-checkout <TAB>` → Open PR numbers (via `gh`)

**Flag Completions:**
All commands support tab completion for:
- Short flags: `-h`, `-i`, `-y`, etc.
- Long flags: `--help`, `--interactive`, `--yes`, etc.
- Descriptions show in completion menu

### Examples
```fish
gw fea<TAB>              # → gw feature/auth
git-pr-checkout 1<TAB>   # → 123, 145, 178 (open PRs)
git-cleanup-all --<TAB>  # → --yes, --skip-worktrees, --skip-branches
```

---

## Advanced Usage

### Tmux/Zellij Status Line

Add compact worktree status to your status line:

**Tmux:**
```tmux
set -g status-right '#(cd #{pane_current_path}; git-worktree-status --compact 2>/dev/null | head -1)'
```

**Zellij:**
Add to your layout config to run `git-worktree-status --compact`.

---

### Automation Scripts

**Daily sync cron job:**
```fish
# Add to crontab
0 9 * * * cd /path/to/repo && git-sync-all --fetch-only
```

**Pre-push hook:**
```fish
# .git/hooks/pre-push
#!/usr/bin/env fish
git-worktree-status
read -P "Continue with push? [Y/n] " confirm
test "$confirm" != "n"
```

---

### Workflow Patterns

**Feature Development:**
```fish
# Start new feature
gw                          # Create new worktree
# ... code, commit ...
git-worktree-status        # Check status
gh pr create               # Create PR

# Review someone's PR
git-pr-checkout 123        # Checkout PR
# ... test, review ...
gh pr review 123 --approve

# Cleanup after merge
git-cleanup-all --yes
```

**Weekly Maintenance:**
```fish
git-sync-all               # Update everything
git-repo-health            # Check health
git-cleanup-all            # Clean up old work
```

**Emergency Hotfix:**
```fish
gw hotfix                  # Quick worktree for hotfix
# ... fix, test, commit ...
git push
gh pr create --fill
# ... get approved, merge ...
git-cleanup-all --yes      # Clean up
```

---

## Tips & Tricks

### Find Old Work
```fish
git-branch-cleanup         # See orphaned branches
# Review what you were working on
# Create worktree or delete
```

### Before Big Refactoring
```fish
git-repo-health            # Ensure clean state
git-sync-all               # Everything up to date
git-worktree-status --all  # No uncommitted work
```

### Disk Space Issues
```fish
git-repo-health            # See sizes
git-cleanup-all --yes      # Clean everything
git worktree prune         # Remove broken refs
git gc --aggressive        # Garbage collect
```

### Multiple Repos
```fish
# Create a sync script
#!/usr/bin/env fish
for repo in ~/dev/*
    echo "Syncing $repo"
    cd $repo
    git-sync-all --fetch-only
end
```

---

## Troubleshooting

### Completions Not Working
```fish
# Reload completions
fisher update arockwell/arock-fish-utils

# Or manually
source ~/.config/fish/completions/gw.fish
```

### `gh` Command Not Found
```fish
# Install GitHub CLI
brew install gh
gh auth login
```

### Worktree Path Not Found
```fish
# Clean up broken worktrees
git worktree prune

# Or use cleanup utility
git-worktree-cleanup --interactive
```

### Performance Issues
```fish
# Use compact mode for large repos
git-worktree-status --compact

# Limit PR results
gh pr list --limit 10
```

---

## Contributing

See main [README.md](../README.md) for contribution guidelines.

## License

MIT License - see [LICENSE](../LICENSE) file for details.
