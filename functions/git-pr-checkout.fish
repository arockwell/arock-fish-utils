#!/usr/bin/env fish
# git-pr-checkout - Quick PR checkout as worktree

function git-pr-checkout --description "Checkout a GitHub PR as a worktree"
    # Check if we're in a git repository
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "❌ Not in a git repository"
        return 1
    end

    # Check if gh is available
    if not command -v gh >/dev/null 2>&1
        echo "❌ gh (GitHub CLI) is required but not installed"
        echo "Install with: brew install gh"
        return 1
    end

    # Parse arguments
    set -l pr_number ""
    set -l auto_yes false

    for arg in $argv
        switch $arg
            case -y --yes
                set auto_yes true
            case -h --help
                echo "Usage: git-pr-checkout [PR_NUMBER] [OPTIONS]"
                echo ""
                echo "Checkout a GitHub PR as a worktree for easy review and testing."
                echo ""
                echo "Arguments:"
                echo "  PR_NUMBER            The PR number to checkout (optional, will show list if not provided)"
                echo ""
                echo "Options:"
                echo "  -y, --yes            Auto-confirm worktree creation"
                echo "  -h, --help           Show this help message"
                echo ""
                echo "Examples:"
                echo "  git-pr-checkout 123              # Checkout PR #123"
                echo "  git-pr-checkout                  # Show list of PRs to choose from"
                echo "  git-pr-checkout 123 --yes        # Auto-confirm"
                return 0
            case '*'
                if string match -qr '^\d+$' -- $arg
                    set pr_number $arg
                end
        end
    end

    # If no PR number provided, show list
    if test -z "$pr_number"
        echo "📋 Fetching open PRs..."
        echo ""

        set -l prs (gh pr list --limit 20 --json number,title,headRefName --jq '.[] | "\(.number):::\(.headRefName):::\(.title)"')

        if test -z "$prs"
            echo "No open PRs found."
            return 0
        end

        echo "Open PRs:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        for pr in $prs
            set -l parts (string split ':::' -- $pr)
            set -l num $parts[1]
            set -l branch $parts[2]
            set -l title $parts[3]
            printf "#%-4s  %-30s  %s\n" $num (string sub -l 30 $branch) $title
        end
        echo ""

        read -l -P "Enter PR number to checkout (or press Enter to cancel): " pr_number
        if test -z "$pr_number"
            echo "Cancelled."
            return 0
        end
    end

    echo "🔍 Fetching PR #$pr_number details..."

    # Get PR info
    set -l pr_info (gh pr view $pr_number --json number,title,headRefName,headRepository 2>&1)

    if test $status -ne 0
        echo "❌ Failed to fetch PR #$pr_number"
        echo "$pr_info"
        return 1
    end

    set -l branch (echo $pr_info | jq -r '.headRefName')
    set -l title (echo $pr_info | jq -r '.title')
    set -l repo (echo $pr_info | jq -r '.headRepository.nameWithOwner')

    echo ""
    echo "PR #$pr_number: $title"
    echo "Branch: $branch"
    echo "Repository: $repo"
    echo ""

    # Determine worktree path
    set -l repo_name (basename (git rev-parse --show-toplevel))
    set -l worktree_base (dirname (git rev-parse --show-toplevel))"/worktrees"
    set -l worktree_path "$worktree_base/$repo_name-pr-$pr_number"

    # Check if worktree already exists
    if test -d "$worktree_path"
        echo "✅ Worktree already exists at: $worktree_path"
        echo ""
        read -l -P "Switch to existing worktree? [Y/n]: " confirm
        if test "$confirm" != "n" -a "$confirm" != "N"
            cd "$worktree_path"
            echo "📂 Switched to: $worktree_path"
        end
        return 0
    end

    echo "Will create worktree at: $worktree_path"
    echo ""

    # Confirm unless --yes
    if test "$auto_yes" = "false"
        read -l -P "Create worktree and checkout PR? [Y/n]: " confirm
        if test "$confirm" = "n" -o "$confirm" = "N"
            echo "Cancelled."
            return 0
        end
    end

    # Fetch the PR
    echo "📥 Fetching PR #$pr_number..."
    if not gh pr checkout $pr_number 2>&1
        echo "❌ Failed to checkout PR"
        return 1
    end

    # Create worktree from the checked out branch
    echo "🔧 Creating worktree..."
    if not git worktree add "$worktree_path" "$branch" 2>&1
        echo "❌ Failed to create worktree"
        # Clean up the branch we just created
        git branch -D "$branch" 2>/dev/null
        return 1
    end

    echo ""
    echo "✅ Worktree created successfully!"
    echo "📂 Path: $worktree_path"
    echo "🌿 Branch: $branch"
    echo ""

    read -l -P "Switch to worktree now? [Y/n]: " switch_now
    if test "$switch_now" != "n" -a "$switch_now" != "N"
        cd "$worktree_path"
        echo "📂 Switched to: $worktree_path"
    else
        echo "💡 To switch later, run: cd $worktree_path"
    end
end
