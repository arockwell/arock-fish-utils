#!/usr/bin/env fish
# Git Worktree Cleanup Function
# Add this to your ~/.config/fish/functions/ directory

function git-worktree-cleanup --description "Analyze and cleanup git worktrees"
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
                echo "Usage: git-worktree-cleanup [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  -i, --interactive    Interactive mode for reviewing MAYBE and REVIEW cases"
                echo "  --delete-merged      Auto-delete all merged worktrees without prompting"
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

    echo "=== Git Worktree Cleanup Analysis ==="
    echo "Main branch: $main_branch"
    echo ""

    # Get all remote branches in ONE network call (parallelized)
    echo "Analyzing worktrees..."
    set -l remote_branches (git ls-remote --heads origin 2>/dev/null | awk '{print $2}' | sed 's|refs/heads/||')

    # Get merged branches once
    set -l merged_branches (git branch --merged $main_branch | string trim)

    # Get all local branches from worktrees first
    set -l branches
    set -l worktree_paths

    set -l current_path ""
    git worktree list --porcelain | while read -l line
        switch $line
            case 'worktree *'
                set current_path (string split ' ' -- $line)[2]
            case 'branch *'
                set -l branch (string replace 'branch refs/heads/' '' -- $line)
                # Only add if not the main branch
                if test "$branch" != "$main_branch"
                    set -a branches $branch
                    set -a worktree_paths $current_path
                end
        end
    end

    # Build git commands in parallel using xargs
    # Get all unmerged counts in one go
    set -l temp_unmerged (mktemp)
    printf "%s\n" $branches | xargs -P 8 -I {} sh -c "echo {}::\$(git rev-list $main_branch..{} --count 2>/dev/null || echo 0)" > $temp_unmerged

    # Get all last commit dates in parallel
    set -l temp_dates (mktemp)
    printf "%s\n" $branches | xargs -P 8 -I {} sh -c "echo {}::\$(git log -1 --format='%as' {} 2>/dev/null || echo unknown)" > $temp_dates

    # Parse worktrees and build results
    set -l all_worktrees
    set -l idx 0

    for branch in $branches
        set idx (math $idx + 1)
        set -l worktree_path $worktree_paths[$idx]

        # Check if remote exists (fast - already fetched)
        set -l has_remote "NO"
        if string match -q "*$branch*" -- $remote_branches
            set has_remote "YES"
        end

        # Get unmerged count from temp file
        set -l unmerged (grep "^$branch::" $temp_unmerged | cut -d: -f3)
        if test -z "$unmerged"
            set unmerged 0
        end

        # Check if merged
        set -l is_merged "NO"
        if string match -q "*$branch*" -- $merged_branches
            set is_merged "YES"
        end

        # Get last date from temp file
        set -l last_date (grep "^$branch::" $temp_dates | cut -d: -f3)
        if test -z "$last_date"
            set last_date "unknown"
        end

        # Check for uncommitted changes (only if directory exists)
        set -l has_changes "NO"
        if test -d "$worktree_path"
            set -l change_count (git -C "$worktree_path" status --short 2>/dev/null | wc -l | string trim)
            if test "$change_count" != "0"
                set has_changes "YES"
            end
        end

        # Store: branch|remote|unmerged|merged|date|changes|path
        set -a all_worktrees "$branch|$has_remote|$unmerged|$is_merged|$last_date|$has_changes|$worktree_path"
    end

    # Cleanup temp files
    rm -f $temp_unmerged $temp_dates

    # Display ALL worktrees in a table
    echo ""
    echo "Branch                           Remote  Unmerged  Merged  Last Update  Changes  Recommendation"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    set -l safe_to_delete
    set -l maybe_delete
    set -l review_changes

    for item in $all_worktrees
        set -l parts (string split '|' -- $item)
        set -l branch $parts[1]
        set -l has_remote $parts[2]
        set -l unmerged $parts[3]
        set -l is_merged $parts[4]
        set -l last_date $parts[5]
        set -l has_changes $parts[6]
        set -l path $parts[7]

        # Determine recommendation
        set -l recommendation ""
        if test "$has_remote" = "NO" -a "$has_changes" = "NO"
            set recommendation "🗑️  DELETE"
            set -a safe_to_delete "$item"
        else if test "$has_remote" = "NO" -a "$has_changes" = "YES"
            set recommendation "⚠️  REVIEW (has changes)"
            set -a review_changes "$item"
        else if test "$unmerged" -gt 5
            set recommendation "⚡ KEEP (active work)"
        else if test "$is_merged" = "YES" -a "$has_changes" = "NO"
            set recommendation "🤔 MAYBE (merged)"
            set -a maybe_delete "$item"
        else
            set recommendation "➡️  KEEP"
        end

        # Format and print row (truncate branch name if needed)
        set -l short_branch (string sub -l 30 $branch)
        printf "%-32s %-6s %-9s %-7s %-12s %-8s %s\n" \
            $short_branch $has_remote $unmerged $is_merged $last_date $has_changes $recommendation
    end

    echo ""

    # Interactive mode - review MAYBE and REVIEW cases
    if test "$interactive_mode" = "true"
        _git_worktree_interactive_review $maybe_delete $review_changes $main_branch
        return
    end

    # Auto-delete merged mode
    if test "$delete_merged" = "true"
        if test (count $maybe_delete) -gt 0
            echo "Auto-deleting "(count $maybe_delete)" merged worktree(s)..."
            for item in $maybe_delete
                set -l parts (string split '|' -- $item)
                git worktree remove $parts[7] 2>/dev/null
                git branch -D $parts[1] 2>/dev/null
                echo "  ✅ Deleted $parts[1]"
            end
            echo "✨ Done!"
        else
            echo "No merged worktrees to delete."
        end
        return
    end

    # Default mode - offer to delete safe ones only
    if test (count $safe_to_delete) -gt 0
        echo "Found "(count $safe_to_delete)" worktree(s) safe to delete (remote deleted, no uncommitted changes)"
        echo ""
        echo "Delete these worktrees? [y/N] "
        read -l confirm
        if test "$confirm" = "y" -o "$confirm" = "Y"
            for item in $safe_to_delete
                set -l parts (string split '|' -- $item)
                git worktree remove $parts[7] 2>/dev/null
                git branch -D $parts[1] 2>/dev/null
                echo "  ✅ Deleted $parts[1]"
            end
            echo ""
            echo "✨ Cleanup complete!"
        else
            echo "Cancelled."
        end
    else
        echo "✨ No worktrees safe to auto-delete."
    end

    # Show hint about interactive mode
    if test (count $maybe_delete) -gt 0 -o (count $review_changes) -gt 0
        echo ""
        echo "💡 Tip: Run with --interactive to review "(count $maybe_delete)" MAYBE and "(count $review_changes)" REVIEW cases interactively"
    end
end

# Helper function for interactive review
function _git_worktree_interactive_review
    set -l maybe_items
    set -l review_items
    set -l main_branch

    # Parse arguments - split maybe and review items
    set -l parsing_maybe true
    for arg in $argv
        if string match -q "*/heads/*" -- $arg
            # This is the main branch indicator
            set main_branch $arg
            set parsing_maybe false
            continue
        end

        if test "$parsing_maybe" = "true"
            if string match -q "*|*" -- $arg
                set -a maybe_items $arg
            else
                # Hit the separator between maybe and review
                set parsing_maybe false
            end
        else
            if string match -q "*|*" -- $arg
                set -a review_items $arg
            end
        end
    end

    echo "=== Interactive Worktree Review ==="
    echo ""

    # Review MAYBE (merged) cases first
    if test (count $maybe_items) -gt 0
        echo "📋 Reviewing "(count $maybe_items)" MAYBE (merged) worktree(s)..."
        echo ""

        for item in $maybe_items
            set -l parts (string split '|' -- $item)
            set -l branch $parts[1]
            set -l path $parts[7]
            set -l last_date $parts[5]

            # Find PR number(s) for this branch
            set -l pr_info (git log --oneline --first-parent main --grep "$branch" -i 2>/dev/null | head -1)
            set -l pr_number ""
            if test -n "$pr_info"
                # Extract PR number from commit message (e.g., "Merge pull request #123")
                set pr_number (echo "$pr_info" | grep -o '#[0-9]\+' | head -1)
            end

            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            if test -n "$pr_number"
                echo "Branch: $branch (PR $pr_number)"
            else
                echo "Branch: $branch"
            end
            echo "Path: $path"
            echo "Last commit: $last_date"
            echo "Status: Merged to main, no uncommitted changes"
            echo ""
            echo "Options:"
            echo "  [d] Delete worktree and branch"
            echo "  [v] View diff vs main"
            echo "  [k] Keep (skip)"
            echo "  [q] Quit interactive mode"
            echo ""
            read -l -P "Action? [d/v/k/q]: " action

            switch $action
                case d D
                    echo "  Removing worktree: $path"
                    if git worktree remove $path 2>&1
                        echo "  Deleting branch: $branch"
                        if git branch -D $branch 2>&1
                            echo "  ✅ Deleted $branch"
                        else
                            echo "  ⚠️  Failed to delete branch $branch"
                        end
                    else
                        echo "  ⚠️  Failed to remove worktree $path"
                    end
                case v V
                    echo ""
                    echo "Branch: $branch"
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

                    # Find the PR merge commit(s) for this branch
                    set -l pr_merges (git log --oneline --first-parent main --grep "$branch" --grep "pull request.*$branch" -i 2>/dev/null | head -3)

                    if test -n "$pr_merges"
                        echo ""
                        echo "Pull Request(s) from this branch:"
                        echo "$pr_merges"
                        echo ""

                        # Get the most recent PR merge
                        set -l latest_pr (echo "$pr_merges" | head -1 | awk '{print $1}')
                        if test -n "$latest_pr"
                            echo "Files changed in latest PR ($latest_pr):"
                            git show --stat --pretty=format:'' $latest_pr 2>/dev/null | grep -v '^\$' | head -30
                        end
                    else
                        echo ""
                        echo "Recent commits on this branch:"
                        git log --oneline $branch -10 2>/dev/null
                    end

                    echo ""
                    echo "Branch details:"
                    echo "  Last commit: $last_date"
                    echo "  Total commits: "(git rev-list --count $branch 2>/dev/null || echo "unknown")
                    echo "  Disk usage: "(du -sh $path 2>/dev/null | awk '{print $1}')
                    echo ""
                    read -l -P "Delete this worktree? [y/N]: " confirm
                    if test "$confirm" = "y" -o "$confirm" = "Y"
                        echo "  Removing worktree: $path"
                        if git worktree remove $path 2>&1
                            echo "  Deleting branch: $branch"
                            if git branch -D $branch 2>&1
                                echo "  ✅ Deleted $branch"
                            else
                                echo "  ⚠️  Failed to delete branch"
                            end
                        else
                            echo "  ⚠️  Failed to remove worktree"
                        end
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

    # Review REVIEW (has changes) cases
    if test (count $review_items) -gt 0
        echo "⚠️  Reviewing "(count $review_items)" worktree(s) with uncommitted changes..."
        echo ""

        for item in $review_items
            set -l parts (string split '|' -- $item)
            set -l branch $parts[1]
            set -l path $parts[7]
            set -l last_date $parts[5]

            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Branch: $branch"
            echo "Path: $path"
            echo "Status: Has uncommitted changes (remote deleted)"
            echo ""

            # Show what changes exist
            if test -d "$path"
                echo "Uncommitted changes:"
                git -C "$path" status --short
                echo ""
            end

            echo "Options:"
            echo "  [s] Save changes to patch file, then delete"
            echo "  [v] View uncommitted changes"
            echo "  [d] Delete anyway (⚠️  loses changes!)"
            echo "  [k] Keep (skip)"
            echo "  [q] Quit interactive mode"
            echo ""
            read -l -P "Action? [s/v/d/k/q]: " action

            switch $action
                case s S
                    # Save to patch
                    set -l patch_file "$HOME/.git-worktree-patches/"(basename $path)"-"(date +%Y%m%d-%H%M%S)".patch"
                    mkdir -p (dirname $patch_file)
                    git -C "$path" diff > $patch_file
                    git -C "$path" diff --cached >> $patch_file
                    echo "  💾 Saved changes to: $patch_file"
                    git worktree remove --force $path 2>/dev/null
                    git branch -D $branch 2>/dev/null
                    echo "  ✅ Deleted $branch"
                case v V
                    echo ""
                    git -C "$path" diff
                    git -C "$path" diff --cached
                    echo ""
                    read -l -P "What to do? [s]ave+delete / [d]elete / [k]eep: " action2
                    if test "$action2" = "s" -o "$action2" = "S"
                        set -l patch_file "$HOME/.git-worktree-patches/"(basename $path)"-"(date +%Y%m%d-%H%M%S)".patch"
                        mkdir -p (dirname $patch_file)
                        git -C "$path" diff > $patch_file
                        git -C "$path" diff --cached >> $patch_file
                        echo "  💾 Saved changes to: $patch_file"
                        git worktree remove --force $path 2>/dev/null
                        git branch -D $branch 2>/dev/null
                        echo "  ✅ Deleted $branch"
                    else if test "$action2" = "d" -o "$action2" = "D"
                        git worktree remove --force $path 2>/dev/null
                        git branch -D $branch 2>/dev/null
                        echo "  ✅ Deleted $branch (changes lost)"
                    else
                        echo "  ⏭️  Skipped $branch"
                    end
                case d D
                    read -l -P "Really delete and lose changes? [y/N]: " confirm
                    if test "$confirm" = "y" -o "$confirm" = "Y"
                        git worktree remove --force $path 2>/dev/null
                        git branch -D $branch 2>/dev/null
                        echo "  ✅ Deleted $branch (changes lost)"
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

    echo "✨ Interactive review complete!"
end
