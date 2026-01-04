#!/usr/bin/env fish
# git-cleanup-all - Run all cleanup utilities in one go

function git-cleanup-all --description "Run all git cleanup utilities"
    # Check if we're in a git repository
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "❌ Not in a git repository"
        return 1
    end

    # Parse arguments
    set -l auto_yes false
    set -l skip_worktrees false
    set -l skip_branches false

    for arg in $argv
        switch $arg
            case -y --yes
                set auto_yes true
            case --skip-worktrees
                set skip_worktrees true
            case --skip-branches
                set skip_branches true
            case -h --help
                echo "Usage: git-cleanup-all [OPTIONS]"
                echo ""
                echo "Run all git cleanup utilities in sequence:"
                echo "  1. Sync all worktrees with remote"
                echo "  2. Clean up old/merged worktrees"
                echo "  3. Clean up merged branches"
                echo "  4. Show repository health status"
                echo ""
                echo "Options:"
                echo "  -y, --yes             Auto-delete merged items without prompting"
                echo "  --skip-worktrees      Skip worktree cleanup"
                echo "  --skip-branches       Skip branch cleanup"
                echo "  -h, --help            Show this help message"
                echo ""
                echo "Examples:"
                echo "  git-cleanup-all                    # Interactive cleanup"
                echo "  git-cleanup-all --yes              # Auto-delete merged items"
                echo "  git-cleanup-all --skip-branches    # Only clean worktrees"
                return 0
        end
    end

    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              🧹 Git Repository Full Cleanup                    ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    # Step 1: Sync all worktrees
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "STEP 1: Syncing Worktrees"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if command -v git-sync-all >/dev/null 2>&1
        git-sync-all
    else
        echo "⚠️  git-sync-all not found, skipping sync step"
        echo ""
    end

    # Step 2: Clean up worktrees
    if test "$skip_worktrees" = "false"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "STEP 2: Cleaning Worktrees"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        if command -v git-worktree-cleanup >/dev/null 2>&1
            if test "$auto_yes" = "true"
                # Auto-delete merged worktrees
                git-worktree-cleanup --delete-merged
            else
                # Interactive mode
                echo "💡 Run 'git-worktree-cleanup --interactive' for detailed review"
                echo ""
                read -l -P "Delete merged worktrees now? [Y/n]: " confirm
                if test "$confirm" != "n" -a "$confirm" != "N"
                    git-worktree-cleanup --delete-merged
                else
                    echo "Skipped worktree cleanup"
                end
            end
        else
            echo "⚠️  git-worktree-cleanup not found, skipping worktree cleanup"
        end
    end

    # Step 3: Clean up branches
    if test "$skip_branches" = "false"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "STEP 3: Cleaning Branches"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        if command -v git-branch-cleanup >/dev/null 2>&1
            if test "$auto_yes" = "true"
                git-branch-cleanup --delete-merged
            else
                # Show analysis and prompt
                git-branch-cleanup
            end
        else
            echo "⚠️  git-branch-cleanup not found, skipping branch cleanup"
        end
    end

    # Step 4: Prune broken worktrees
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "STEP 4: Pruning Broken References"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    echo "🔧 Pruning broken worktree references..."
    git worktree prune -v
    echo ""

    echo "🔧 Pruning deleted remote branches..."
    git remote prune origin
    echo ""

    # Step 5: Show health status
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "STEP 5: Repository Health Check"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if command -v git-repo-health >/dev/null 2>&1
        git-repo-health
    else
        echo "⚠️  git-repo-health not found, showing basic git status"
        echo ""
        git status
    end

    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                  ✨ Cleanup Complete!                          ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    # Show quick tips
    echo "💡 Quick Tips:"
    echo "  • Use 'gw' to quickly switch between worktrees"
    echo "  • Use 'git-pr-checkout <pr#>' to review PRs in worktrees"
    echo "  • Use 'git-sync-all' to keep all worktrees up to date"
    echo "  • Use 'git-cleanup-all --yes' for automated cleanup"
    echo ""
end
