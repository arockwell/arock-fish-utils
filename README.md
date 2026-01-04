# 🐟 arock-fish-utils

Alex Rockwell's collection of Fish utilities for advanced Git workflow management.

## ✨ Features

### Git Worktree Management
- **`gw`** - Fast fuzzy search worktree switcher with **interactive preview** (status + commits)
- **`gwp`** - Print worktree path by branch name (perfect for scripts and aliases)
- **`git-worktree-status`** - Quick one-line status for all worktrees (emoji indicators)
- **`git-worktree-cleanup`** - Analyze and clean up old/merged worktrees (interactive mode available)
- **`git-pr-checkout`** - Quickly checkout GitHub PRs as worktrees for easy review

### Git Branch Management
- **`git-branch-cleanup`** - Clean up local branches (merged, orphaned, no remote)

### Repository Health & Sync
- **`git-repo-health`** - Comprehensive repository health dashboard (disk usage, branches, worktrees, unpushed commits)
- **`git-sync-all`** - Sync all worktrees with remote branches
- **`git-cleanup-all`** - Run all cleanup utilities in one command
- **`git-dashboard`** - **NEW!** Interactive TUI dashboard for all git workflow operations

### Productivity Features
- **Fish abbreviations** - Quick shortcuts (`gws`, `gca`, `gpc`, `gd`, etc.)
- **Tab completions** - Branch names, PR numbers, and all command flags
- **Script-friendly** - `gwp` for path resolution in scripts and aliases

## 📦 Installation

### With Fisher
\`\`\`fish
fisher install your-username/arock-fish-utils
\`\`\`

### Manual Installation
\`\`\`fish
git clone https://github.com/your-username/arock-fish-utils.git
cd arock-fish-utils
fisher install .
\`\`\`

## 🛠️ Development

### Adding Functions
Create new functions in the \`functions/\` directory:

\`\`\`fish
# functions/my-function.fish
function my-function -d "Description of my function"
    # Your function code here
end
\`\`\`

### Adding Completions
Add tab completions in the \`completions/\` directory:

\`\`\`fish
# completions/my-function.fish
complete -c my-function -s h -l help -d "Show help"
\`\`\`

### Configuration
Add startup configuration in \`conf.d/arock-fish-utils.fish\`

## 📖 Usage Examples

### Interactive Dashboard (NEW!)
```fish
git-dashboard        # Launch interactive TUI dashboard
gd                   # Abbreviation for git-dashboard
```

### Enhanced Worktree Switching
```fish
gw                   # Fuzzy search with preview (status + commits)
gw feature           # Search with initial query
gwp feature          # Print path to feature worktree
cd $(gwp main)       # Navigate to main worktree
code $(gwp pr-123)   # Open worktree in VS Code
```

### PR Review Workflow
```fish
git-pr-checkout      # List and select a PR
git-pr-checkout 123  # Checkout PR #123 as worktree
gpc 123              # Abbreviation
```

### Quick Abbreviations
```fish
gws                  # git-worktree-status
gsa                  # git-sync-all
gca                  # git-cleanup-all
grh                  # git-repo-health
gd                   # git-dashboard
```

### Repository Maintenance
```fish
git-worktree-status             # Quick status overview (emoji indicators)
git-worktree-status --all       # Show all worktrees including clean ones
git-worktree-status --compact   # Ultra-compact emoji-only mode

git-sync-all                    # Sync all worktrees with remote
git-cleanup-all                 # Full cleanup (interactive)
git-cleanup-all --yes           # Auto-delete merged items
git-repo-health                 # View repository health dashboard
```

### Interactive Cleanup
```fish
git-worktree-cleanup --interactive    # Review worktrees one by one
git-branch-cleanup --interactive      # Review branches one by one
```

## 🤝 Contributing

1. 🍴 Fork the repository
2. 🌟 Create a feature branch
3. 💾 Commit your changes
4. 📤 Push to the branch
5. 🎉 Create a Pull Request

## 📄 License

MIT License - see LICENSE file for details.
