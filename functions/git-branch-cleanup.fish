#!/usr/bin/env fish
# git-branch-cleanup - Clean up local branches that are no longer needed

function git-branch-cleanup --description "Clean up local git branches"
    # Parse arguments
    set -l interactive_mode false
    set -l delete_merged false

    for arg in $argv
        switch $arg
            case -i --interactive
                set interactive_mode true
            case --delete-merged
                set delete_merged true
            case -h --help
                echo "Usage: git-branch-cleanup [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  -i, --interactive    Interactive mode for reviewing branches"
                echo "  --delete-merged      Auto-delete all merged branches without prompting"
                echo "  -h, --help           Show this help message"
                return 0
        end
    end

    # Check if we're in a git repository
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "❌ Not in a git repository"
        return 1
    end

    set -l main_branch (git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    if test -z "$main_branch"
        set main_branch "main"
    end

    echo "=== Git Branch Cleanup Analysis ==="
    echo "Main branch: $main_branch"
    echo ""
    echo "Analyzing local branches..."

    # Get all local branches except main
    set -l all_branches (git branch --format='%(refname:short)' | grep -v "^$main_branch\$")

    # Get branches that are in worktrees
    set -l worktree_branches
    git worktree list --porcelain | while read -l line
        if string match -q 'branch *' -- $line
            set -l branch (string replace 'branch refs/heads/' '' -- $line)
            if test "$branch" != "$main_branch"
                echo $branch
            end
        end
    end | read -z worktree_branches
    set worktree_branches (string split \n -- $worktree_branches)

    # Get merged branches
    set -l merged_branches (git branch --merged $main_branch --format='%(refname:short)' | grep -v "^$main_branch\$")

    # Get remote branches for comparison
    set -l remote_branches (git ls-remote --heads origin 2>/dev/null | awk '{print $2}' | sed 's|refs/heads/||')

    # Categorize branches
    set -l orphaned      # Not in any worktree, not merged
    set -l merged_safe   # Merged to main, not in worktree
    set -l no_remote     # No remote tracking
    set -l safe_to_keep  # In a worktree

    echo ""
    echo "Branch                           In Worktree  Merged  Has Remote  Recommendation"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    for branch in $all_branches
        set -l in_worktree "NO"
        if contains $branch $worktree_branches
            set in_worktree "YES"
        end

        set -l is_merged "NO"
        if contains $branch $merged_branches
            set is_merged "YES"
        end

        set -l has_remote "NO"
        if string match -q "*$branch*" -- $remote_branches
            set has_remote "YES"
        end

        # Determine recommendation
        set -l recommendation ""
        if test "$in_worktree" = "YES"
            set recommendation "✅ KEEP (in worktree)"
            set -a safe_to_keep $branch
        else if test "$is_merged" = "YES"
            set recommendation "🗑️  DELETE (merged)"
            set -a merged_safe $branch
        else if test "$has_remote" = "NO"
            set recommendation "⚠️  REVIEW (no remote)"
            set -a no_remote $branch
        else
            set recommendation "❓ ORPHANED (not in worktree)"
            set -a orphaned $branch
        end

        # Format output
        set -l short_branch (string sub -l 30 $branch)
        printf "%-32s %-12s %-7s %-11s %s\n" \
            $short_branch $in_worktree $is_merged $has_remote $recommendation
    end

    echo ""

    # Interactive mode
    if test "$interactive_mode" = "true"
        _git_branch_cleanup_interactive $merged_safe $orphaned $no_remote
        return
    end

    # Auto-delete merged mode
    if test "$delete_merged" = "true"
        if test (count $merged_safe) -gt 0
            echo "Auto-deleting "(count $merged_safe)" merged branches..."
            for branch in $merged_safe
                git branch -D $branch 2>&1
                echo "  ✅ Deleted $branch"
            end
            echo "✨ Done!"
        else
            echo "No merged branches to delete."
        end
        return
    end

    # Summary
    echo "Summary:"
    echo "  ✅ Safe to keep (in worktree): "(count $safe_to_keep)
    echo "  🗑️  Safe to delete (merged): "(count $merged_safe)
    echo "  ❓ Orphaned (not in worktree): "(count $orphaned)
    echo "  ⚠️  No remote: "(count $no_remote)
    echo ""

    # Offer to delete merged branches
    if test (count $merged_safe) -gt 0
        echo "Delete "(count $merged_safe)" merged branches? [y/N] "
        read -l confirm
        if test "$confirm" = "y" -o "$confirm" = "Y"
            for branch in $merged_safe
                git branch -D $branch 2>&1
                echo "  ✅ Deleted $branch"
            end
            echo ""
            echo "✨ Cleanup complete!"
        else
            echo "Cancelled."
        end
    end

    # Show hint about interactive mode
    if test (count $orphaned) -gt 0 -o (count $no_remote) -gt 0
        echo ""
        echo "💡 Tip: Run with --interactive to review "(count $orphaned)" orphaned and "(count $no_remote)" no-remote branches"
    end
end

# Helper function for interactive cleanup
function _git_branch_cleanup_interactive
    set -l merged_list
    set -l orphaned_list
    set -l no_remote_list

    # Parse arguments
    set -l current_list merged_list
    for arg in $argv
        if test "$arg" = ""
            # Empty arg means switch to next list
            if test "$current_list" = "merged_list"
                set current_list orphaned_list
            else if test "$current_list" = "orphaned_list"
                set current_list no_remote_list
            end
        else
            eval "set -a $current_list $arg"
        end
    end

    echo "=== Interactive Branch Cleanup ==="
    echo ""

    # Review merged branches
    if test (count $merged_list) -gt 0
        echo "🗑️  Reviewing "(count $merged_list)" merged branches..."
        echo ""

        for branch in $merged_list
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Branch: $branch"
            echo "Status: Merged to main, safe to delete"
            echo ""

            # Show last commit
            set -l last_commit (git log -1 --oneline $branch 2>/dev/null)
            echo "Last commit: $last_commit"
            echo ""

            echo "Options:"
            echo "  [d] Delete branch"
            echo "  [v] View commits"
            echo "  [k] Keep (skip)"
            echo "  [q] Quit"
            echo ""
            read -l -P "Action? [d/v/k/q]: " action

            switch $action
                case d D
                    if git branch -D $branch 2>&1
                        echo "  ✅ Deleted $branch"
                    else
                        echo "  ⚠️  Failed to delete $branch"
                    end
                case v V
                    echo ""
                    git log --oneline $branch -10
                    echo ""
                    read -l -P "Delete this branch? [y/N]: " confirm
                    if test "$confirm" = "y" -o "$confirm" = "Y"
                        git branch -D $branch 2>&1
                        echo "  ✅ Deleted $branch"
                    else
                        echo "  ⏭️  Skipped $branch"
                    end
                case k K
                    echo "  ⏭️  Skipped $branch"
                case q Q
                    echo "Exiting interactive mode."
                    return
                case '*'
                    echo "  ⏭️  Skipped $branch (invalid option)"
            end
            echo ""
        end
    end

    # Review orphaned branches
    if test (count $orphaned_list) -gt 0
        echo "❓ Reviewing "(count $orphaned_list)" orphaned branches (not in any worktree)..."
        echo ""

        for branch in $orphaned_list
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Branch: $branch"
            echo "Status: Not in any worktree, not merged"
            echo ""

            # Show last commit and age
            set -l last_commit (git log -1 --format="%ai - %s" $branch 2>/dev/null)
            echo "Last commit: $last_commit"
            echo ""

            echo "Options:"
            echo "  [d] Delete branch"
            echo "  [v] View commits"
            echo "  [w] Create worktree for this branch"
            echo "  [k] Keep (skip)"
            echo "  [q] Quit"
            echo ""
            read -l -P "Action? [d/v/w/k/q]: " action

            switch $action
                case d D
                    read -l -P "Really delete unmerged branch? [y/N]: " confirm
                    if test "$confirm" = "y" -o "$confirm" = "Y"
                        git branch -D $branch 2>&1
                        echo "  ✅ Deleted $branch"
                    else
                        echo "  ⏭️  Skipped $branch"
                    end
                case v V
                    echo ""
                    git log --oneline $branch -10
                    echo ""
                    read -l -P "What to do? [d]elete / [w]orktree / [k]eep: " action2
                    switch $action2
                        case d D
                            read -l -P "Really delete? [y/N]: " confirm
                            if test "$confirm" = "y" -o "$confirm" = "Y"
                                git branch -D $branch 2>&1
                                echo "  ✅ Deleted $branch"
                            end
                        case w W
                            # Create worktree
                            set -l repo_name (basename (git rev-parse --show-toplevel))
                            set -l worktree_path (dirname (git rev-parse --show-toplevel))"/worktrees/$repo_name-$branch"
                            git worktree add "$worktree_path" "$branch"
                            echo "  ✅ Created worktree at $worktree_path"
                        case '*'
                            echo "  ⏭️  Skipped $branch"
                    end
                case w W
                    set -l repo_name (basename (git rev-parse --show-toplevel))
                    set -l worktree_path (dirname (git rev-parse --show-toplevel))"/worktrees/$repo_name-$branch"
                    git worktree add "$worktree_path" "$branch"
                    echo "  ✅ Created worktree at $worktree_path"
                case k K
                    echo "  ⏭️  Skipped $branch"
                case q Q
                    echo "Exiting interactive mode."
                    return
                case '*'
                    echo "  ⏭️  Skipped $branch (invalid option)"
            end
            echo ""
        end
    end

    echo "✨ Interactive cleanup complete!"
end
