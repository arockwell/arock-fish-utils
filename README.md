# 🐟 arock-fish-utils

Alex Rockwell's collection of Fish utilities for advanced Git workflow management.

## ✨ Features

### Git Worktree Management
- **`gw`** - Fast fuzzy search worktree switcher with create functionality
- **`git-worktree-cleanup`** - Analyze and clean up old/merged worktrees (interactive mode available)
- **`git-pr-checkout`** - Quickly checkout GitHub PRs as worktrees for easy review

### Git Branch Management
- **`git-branch-cleanup`** - Clean up local branches (merged, orphaned, no remote)

### Repository Health & Sync
- **`git-repo-health`** - Comprehensive repository health dashboard (disk usage, branches, worktrees, unpushed commits)
- **`git-sync-all`** - Sync all worktrees with remote branches
- **`git-cleanup-all`** - Run all cleanup utilities in one command

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

### Quick Worktree Switching
```fish
gw                    # Fuzzy search and switch to a worktree
gw feature           # Search with initial query
```

### PR Review Workflow
```fish
git-pr-checkout      # List and select a PR
git-pr-checkout 123  # Checkout PR #123 as worktree
```

### Repository Maintenance
```fish
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
