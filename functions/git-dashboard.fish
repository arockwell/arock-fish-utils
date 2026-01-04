#!/usr/bin/env fish
# git-dashboard - Interactive TUI dashboard for git workflow management

function git-dashboard --description "Interactive dashboard for git workflow management"
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

    set -l running true

    while test "$running" = "true"
        # Build dashboard menu
        set -l menu_items
        set -a menu_items "📊 Repository Health             View overall repository status"
        set -a menu_items "🔄 Sync All Worktrees            Fetch and pull all worktrees"
        set -a menu_items "📝 Worktree Status               Quick status of all worktrees"
        set -a menu_items "🔧 Switch Worktree (gw)          Fuzzy search and switch worktrees"
        set -a menu_items "📥 Checkout PR                   Checkout a GitHub PR as worktree"
        set -a menu_items "🗑️  Cleanup Worktrees            Clean up old/merged worktrees"
        set -a menu_items "🌿 Cleanup Branches              Clean up local branches"
        set -a menu_items "🧹 Full Cleanup                  Run all cleanup utilities"
        set -a menu_items "❌ Exit                          Close dashboard"

        # Show menu with preview
        set -l selected (printf "%s\n" $menu_items | fzf \
            --height=100% \
            --reverse \
            --ansi \
            --preview='if echo {} | grep -q "Repository Health"; then echo "📊 Repository Health Dashboard"; echo ""; echo "Shows comprehensive repository information:"; echo "  • Disk usage (repo, worktrees, .git)"; echo "  • Branch statistics and stale branches"; echo "  • Worktree status and uncommitted work"; echo "  • Unpushed commits"; echo "  • Cleanup recommendations"; elif echo {} | grep -q "Sync All"; then echo "🔄 Sync All Worktrees"; echo ""; echo "Syncs all worktrees with remote:"; echo "  • Fetches all remotes"; echo "  • Shows sync status for each worktree"; echo "  • Auto-pulls clean worktrees"; echo "  • Reports issues (dirty, diverged)"; elif echo {} | grep -q "Worktree Status"; then echo "📝 Worktree Status"; echo ""; echo "Quick one-line status for all worktrees:"; echo "  ✅ Clean and up-to-date"; echo "  📝 Uncommitted changes"; echo "  📤 Unpushed commits"; echo "  📥 Behind remote"; echo "  ⚠️  Diverged from remote"; elif echo {} | grep -q "Switch Worktree"; then echo "🔧 Switch Worktree (gw)"; echo ""; echo "Fuzzy search and switch worktrees:"; echo "  • Interactive preview with status"; echo "  • Shows recent commits"; echo "  • Create new worktrees"; echo "  • Tab completion support"; elif echo {} | grep -q "Checkout PR"; then echo "📥 Checkout PR"; echo ""; echo "Checkout GitHub PRs as worktrees:"; echo "  • List open PRs"; echo "  • Create worktree for review"; echo "  • Automatic PR fetching"; echo "  • Quick PR testing workflow"; elif echo {} | grep -q "Cleanup Worktrees"; then echo "🗑️  Cleanup Worktrees"; echo ""; echo "Clean up old/merged worktrees:"; echo "  • Interactive review mode"; echo "  • Auto-delete merged worktrees"; echo "  • Show PR context"; echo "  • Safe cleanup recommendations"; elif echo {} | grep -q "Cleanup Branches"; then echo "🌿 Cleanup Branches"; echo ""; echo "Clean up local branches:"; echo "  • Show merged/orphaned branches"; echo "  • Interactive review"; echo "  • Create worktrees for orphaned branches"; echo "  • Safe deletion of merged branches"; elif echo {} | grep -q "Full Cleanup"; then echo "🧹 Full Cleanup"; echo ""; echo "Complete repository cleanup:"; echo "  1. Sync all worktrees"; echo "  2. Clean up worktrees"; echo "  3. Clean up branches"; echo "  4. Prune broken references"; echo "  5. Show health status"; elif echo {} | grep -q "Exit"; then echo "❌ Exit Dashboard"; echo ""; echo "Close the dashboard and return to shell"; fi' \
            --preview-window=right:50%:wrap \
            --border \
            --prompt="Git Dashboard> " \
            --header="↑↓: navigate | ENTER: execute | ESC: exit" \
            --bind="ctrl-/:toggle-preview" \
            --no-info)

        # Check if user cancelled
        if test -z "$selected"
            break
        end

        # Clear screen for command execution
        clear

        # Execute selected action
        if string match -q "*Repository Health*" -- $selected
            git-repo-health
            read -P "Press ENTER to continue..."
        else if string match -q "*Sync All*" -- $selected
            git-sync-all
            read -P "Press ENTER to continue..."
        else if string match -q "*Worktree Status*" -- $selected
            git-worktree-status --all
            read -P "Press ENTER to continue..."
        else if string match -q "*Switch Worktree*" -- $selected
            gw
            # gw handles its own navigation, return to dashboard
        else if string match -q "*Checkout PR*" -- $selected
            git-pr-checkout
            read -P "Press ENTER to continue..."
        else if string match -q "*Cleanup Worktrees*" -- $selected
            echo "Choose cleanup mode:"
            echo "  [1] View analysis"
            echo "  [2] Interactive mode"
            echo "  [3] Auto-delete merged"
            echo ""
            read -P "Selection [1-3]: " mode
            switch $mode
                case 1
                    git-worktree-cleanup
                case 2
                    git-worktree-cleanup --interactive
                case 3
                    git-worktree-cleanup --delete-merged
                case '*'
                    git-worktree-cleanup
            end
            read -P "Press ENTER to continue..."
        else if string match -q "*Cleanup Branches*" -- $selected
            echo "Choose cleanup mode:"
            echo "  [1] View analysis"
            echo "  [2] Interactive mode"
            echo "  [3] Auto-delete merged"
            echo ""
            read -P "Selection [1-3]: " mode
            switch $mode
                case 1
                    git-branch-cleanup
                case 2
                    git-branch-cleanup --interactive
                case 3
                    git-branch-cleanup --delete-merged
                case '*'
                    git-branch-cleanup
            end
            read -P "Press ENTER to continue..."
        else if string match -q "*Full Cleanup*" -- $selected
            echo "Run full cleanup?"
            echo "  [1] Interactive (recommended)"
            echo "  [2] Auto-delete merged items"
            echo ""
            read -P "Selection [1-2]: " mode
            switch $mode
                case 1
                    git-cleanup-all
                case 2
                    git-cleanup-all --yes
                case '*'
                    git-cleanup-all
            end
            read -P "Press ENTER to continue..."
        else if string match -q "*Exit*" -- $selected
            set running false
        end

        # Clear screen before showing menu again
        clear
    end

    echo "👋 Exited git dashboard"
end
