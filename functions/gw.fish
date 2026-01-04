#!/usr/bin/env fish
# gw - Git Worktree switcher
# Fast fuzzy search and switch to worktrees

function gw --description "Switch to git worktree (or create new one)"
    # Check if we're in a git repository
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "❌ Not in a git repository"
        return 1
    end

    # Check if fzf is available
    if not command -v fzf >/dev/null 2>&1
        echo "❌ fzf is required but not installed"
        echo "Install with: brew install fzf"
        return 1
    end

    set -l query "$argv"

    # Get worktree list and format it nicely
    # Format: "branch-name → /path/to/worktree"
    set -l formatted_list
    git worktree list | while read -l line
        # Extract path (first field)
        set -l path (echo $line | awk '{print $1}')
        # Extract branch (text between [ and ])
        set -l branch (echo $line | grep -o '\[.*\]' | tr -d '[]')

        if test -n "$branch"
            set -a formatted_list "$branch → $path"
        end
    end

    # Add create option
    set -a formatted_list "+ Create new worktree"

    # Use fzf to select
    set -l selected
    if test -n "$query"
        set selected (printf "%s\n" $formatted_list | fzf --height=40% --reverse --query="$query" --select-1 --exit-0)
    else
        set selected (printf "%s\n" $formatted_list | fzf --height=40% --reverse)
    end

    # Check if user cancelled
    if test -z "$selected"
        return 0
    end

    # Handle selection
    if test "$selected" = "+ Create new worktree"
        _gw_create_worktree
    else
        # Extract path (everything after " → ")
        set -l path (echo $selected | sed 's/.* → //')
        set -l branch (echo $selected | sed 's/ →.*//')

        if test -d "$path"
            echo "Switching to: $branch"
            cd "$path"
        else
            echo "⚠️  Worktree directory not found: $path"
            return 1
        end
    end
end

# Helper function to create new worktree
function _gw_create_worktree
    echo ""
    echo "=== Create New Worktree ==="
    echo ""

    # Get branch name
    read -l -P "Branch name (or press Enter to cancel): " branch_name
    if test -z "$branch_name"
        echo "Cancelled."
        return 0
    end

    # Determine worktree path
    set -l repo_name (basename (git rev-parse --show-toplevel))
    set -l worktree_base (dirname (git rev-parse --show-toplevel))"/worktrees"
    set -l worktree_path "$worktree_base/$repo_name-$branch_name"

    echo ""
    echo "Will create worktree:"
    echo "  Branch: $branch_name"
    echo "  Path: $worktree_path"
    echo ""

    # Check if branch exists locally
    if git show-ref --verify --quiet refs/heads/$branch_name
        echo "Branch '$branch_name' exists locally"
        read -l -P "Create worktree from existing branch? [Y/n]: " confirm
        if test "$confirm" = "n" -o "$confirm" = "N"
            echo "Cancelled."
            return 0
        end
        git worktree add "$worktree_path" "$branch_name"
    else if git ls-remote --heads origin $branch_name 2>/dev/null | grep -q $branch_name
        echo "Branch '$branch_name' exists on remote"
        read -l -P "Create worktree and track remote branch? [Y/n]: " confirm
        if test "$confirm" = "n" -o "$confirm" = "N"
            echo "Cancelled."
            return 0
        end
        git worktree add --track -b "$branch_name" "$worktree_path" "origin/$branch_name"
    else
        echo "Branch '$branch_name' doesn't exist"
        read -l -P "Create new branch from current HEAD? [Y/n]: " confirm
        if test "$confirm" = "n" -o "$confirm" = "N"
            echo "Cancelled."
            return 0
        end
        git worktree add -b "$branch_name" "$worktree_path"
    end

    if test $status -eq 0
        echo ""
        echo "✅ Worktree created successfully!"
        echo "Switching to: $worktree_path"
        cd "$worktree_path"
    else
        echo ""
        echo "❌ Failed to create worktree"
        return 1
    end
end
