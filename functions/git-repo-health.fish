#!/usr/bin/env fish
# git-repo-health - Overall repository health dashboard

function git-repo-health --description "Show overall git repository health"
    # Check if we're in a git repository
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "❌ Not in a git repository"
        return 1
    end

    set -l main_branch (git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    if test -z "$main_branch"
        set main_branch "main"
    end

    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                  🏥 Git Repository Health                      ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    # Repository info
    set -l repo_name (basename (git rev-parse --show-toplevel))
    set -l repo_path (git rev-parse --show-toplevel)
    echo "📁 Repository: $repo_name"
    echo "📂 Path: $repo_path"
    echo "🌿 Main branch: $main_branch"
    echo ""

    # ═══════════════════════════════════════════════════════════════
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 DISK USAGE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Main repo size
    set -l main_size (du -sh $repo_path 2>/dev/null | awk '{print $1}')
    echo "Main repository: $main_size"

    # Worktree sizes
    set -l worktree_count 0
    set -l total_worktree_size 0
    git worktree list --porcelain | while read -l line
        switch $line
            case 'worktree *'
                set -l path (string split ' ' -- $line)[2]
                if test "$path" != "$repo_path"
                    set worktree_count (math $worktree_count + 1)
                    set -l size (du -sh $path 2>/dev/null | awk '{print $1}')
                    echo "  Worktree: $size - $path"
                end
        end
    end

    if test $worktree_count -eq 0
        echo "  No additional worktrees"
    end

    # .git size
    set -l git_dir_size (du -sh (git rev-parse --git-dir) 2>/dev/null | awk '{print $1}')
    echo ".git directory: $git_dir_size"
    echo ""

    # ═══════════════════════════════════════════════════════════════
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌿 BRANCHES"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    set -l total_branches (git branch -a | wc -l | string trim)
    set -l local_branches (git branch | wc -l | string trim)
    set -l remote_branches (git branch -r | wc -l | string trim)
    set -l merged_branches (git branch --merged $main_branch | grep -v "^\*" | grep -v "$main_branch" | wc -l | string trim)

    echo "Total branches: $total_branches"
    echo "  Local: $local_branches"
    echo "  Remote: $remote_branches"
    echo "  Merged (deletable): $merged_branches"

    # Stale branches (no activity in 90+ days)
    set -l stale_count 0
    set -l cutoff_timestamp (date -v-90d '+%s' 2>/dev/null; or date -d '90 days ago' '+%s' 2>/dev/null)

    echo ""
    echo "Stale branches (90+ days old):"
    set -l stale_branches
    git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short) %(committerdate:short)' | while read -l branch date
        if test "$branch" != "$main_branch"
            set -l branch_timestamp (date -j -f '%Y-%m-%d' $date '+%s' 2>/dev/null; or date -d $date '+%s' 2>/dev/null)
            if test "$branch_timestamp" -lt "$cutoff_timestamp"
                echo "  ⚠️  $branch (last: $date)"
                set -a stale_branches $branch
            end
        end
    end | head -10

    set stale_count (count $stale_branches)
    if test $stale_count -eq 0
        echo "  ✅ No stale branches"
    else if test $stale_count -gt 10
        echo "  ... and "(math $stale_count - 10)" more"
    end
    echo ""

    # ═══════════════════════════════════════════════════════════════
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔧 WORKTREES"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    set -l worktree_total (git worktree list | wc -l | string trim)
    echo "Total worktrees: $worktree_total"
    echo ""

    # Check for uncommitted work
    echo "Uncommitted work:"
    set -l uncommitted_count 0
    git worktree list --porcelain | while read -l line
        switch $line
            case 'worktree *'
                set -l path (string split ' ' -- $line)[2]
                set -l branch ""
            case 'branch *'
                set branch (string replace 'branch refs/heads/' '' -- $line)
                if test -d "$path"
                    set -l changes (git -C $path status --short 2>/dev/null | wc -l | string trim)
                    if test $changes -gt 0
                        echo "  ⚠️  $branch - $changes file(s) changed"
                        set uncommitted_count (math $uncommitted_count + 1)
                    end
                end
        end
    end

    if test $uncommitted_count -eq 0
        echo "  ✅ All worktrees clean"
    end
    echo ""

    # ═══════════════════════════════════════════════════════════════
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⬆️  UNPUSHED COMMITS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    set -l unpushed_count 0
    git for-each-ref --format='%(refname:short) %(upstream:short)' refs/heads | while read -l branch upstream
        if test -n "$upstream"
            set -l ahead (git rev-list --count $upstream..$branch 2>/dev/null)
            if test "$ahead" -gt 0
                echo "  📤 $branch - $ahead commit(s) ahead of $upstream"
                set unpushed_count (math $unpushed_count + 1)
            end
        end
    end

    if test $unpushed_count -eq 0
        echo "  ✅ All branches pushed"
    end
    echo ""

    # ═══════════════════════════════════════════════════════════════
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎯 RECOMMENDATIONS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    set -l has_recommendations false

    if test $merged_branches -gt 0
        echo "  🗑️  Run 'git-branch-cleanup --delete-merged' to remove $merged_branches merged branches"
        set has_recommendations true
    end

    if test $stale_count -gt 0
        echo "  ⏰ Review $stale_count stale branches (90+ days old)"
        set has_recommendations true
    end

    if test $uncommitted_count -gt 0
        echo "  💾 Commit or stash changes in $uncommitted_count worktree(s)"
        set has_recommendations true
    end

    if test $unpushed_count -gt 0
        echo "  📤 Push $unpushed_count branch(es) with unpushed commits"
        set has_recommendations true
    end

    # Check for orphaned worktree paths
    set -l broken_worktrees 0
    git worktree list --porcelain | while read -l line
        switch $line
            case 'worktree *'
                set -l path (string split ' ' -- $line)[2]
                if not test -d "$path"
                    set broken_worktrees (math $broken_worktrees + 1)
                end
        end
    end

    if test $broken_worktrees -gt 0
        echo "  🔧 Run 'git worktree prune' to clean up $broken_worktrees broken worktree(s)"
        set has_recommendations true
    end

    if test "$has_recommendations" = "false"
        echo "  ✅ Repository is in good health!"
    end

    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  💡 Use git-worktree-cleanup, git-branch-cleanup, or gw       ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
end
