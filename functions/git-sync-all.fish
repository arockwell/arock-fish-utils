#!/usr/bin/env fish
# git-sync-all - Sync all worktrees with remote

function git-sync-all --description "Sync all worktrees with remote"
    # Check if we're in a git repository
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "❌ Not in a git repository"
        return 1
    end

    # Parse arguments
    set -l fetch_only false
    set -l show_clean false

    for arg in $argv
        switch $arg
            case -f --fetch-only
                set fetch_only true
            case -a --all
                set show_clean true
            case -h --help
                echo "Usage: git-sync-all [OPTIONS]"
                echo ""
                echo "Sync all worktrees with their remote branches."
                echo ""
                echo "Options:"
                echo "  -f, --fetch-only     Only fetch, don't pull"
                echo "  -a, --all            Show all worktrees including clean ones"
                echo "  -h, --help           Show this help message"
                echo ""
                echo "This command will:"
                echo "  1. Fetch all remotes"
                echo "  2. Check each worktree's sync status"
                echo "  3. Pull updates if safe (clean working directory)"
                echo "  4. Report any issues or conflicts"
                return 0
        end
    end

    set -l main_branch (git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    if test -z "$main_branch"
        set main_branch "main"
    end

    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                  🔄 Syncing All Worktrees                      ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    # Step 1: Fetch all
    echo "📥 Fetching from all remotes..."
    git fetch --all --prune 2>&1 | grep -v "^Fetching" || true
    echo ""

    # Step 2: Analyze each worktree
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 Worktree Status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    set -l total_synced 0
    set -l total_ahead 0
    set -l total_behind 0
    set -l total_diverged 0
    set -l total_dirty 0
    set -l total_no_remote 0

    # Parse worktrees
    set -l current_path ""
    set -l current_branch ""

    git worktree list --porcelain | while read -l line
        switch $line
            case 'worktree *'
                set current_path (string split ' ' -- $line)[2]
            case 'branch *'
                set current_branch (string replace 'branch refs/heads/' '' -- $line)

                if not test -d "$current_path"
                    echo "⚠️  $current_branch - BROKEN (path doesn't exist)"
                    continue
                end

                # Get upstream
                set -l upstream (git -C "$current_path" rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)

                if test -z "$upstream"
                    if test "$show_clean" = "true"
                        echo "📍 $current_branch - NO REMOTE TRACKING"
                    end
                    set total_no_remote (math $total_no_remote + 1)
                    continue
                end

                # Check if working directory is clean
                set -l is_dirty (git -C "$current_path" status --short 2>/dev/null | wc -l | string trim)

                # Get ahead/behind counts
                set -l ahead (git -C "$current_path" rev-list --count $upstream..HEAD 2>/dev/null)
                set -l behind (git -C "$current_path" rev-list --count HEAD..$upstream 2>/dev/null)

                # Determine status
                if test "$is_dirty" -gt 0
                    echo "⚠️  $current_branch - DIRTY ($is_dirty changes)"
                    set total_dirty (math $total_dirty + 1)
                else if test "$ahead" -gt 0 -a "$behind" -gt 0
                    echo "⚠️  $current_branch - DIVERGED (↑$ahead ↓$behind)"
                    set total_diverged (math $total_diverged + 1)
                else if test "$ahead" -gt 0
                    if test "$show_clean" = "true"
                        echo "📤 $current_branch - AHEAD (↑$ahead)"
                    end
                    set total_ahead (math $total_ahead + 1)
                else if test "$behind" -gt 0
                    if test "$fetch_only" = "false"
                        echo "📥 $current_branch - PULLING (↓$behind)..."
                        if git -C "$current_path" pull --ff-only 2>&1 | grep -v "^Already up to date" | grep -v "^Updating"
                            echo "  ✅ Pulled successfully"
                        end
                        set total_behind (math $total_behind + 1)
                    else
                        echo "📥 $current_branch - BEHIND (↓$behind)"
                        set total_behind (math $total_behind + 1)
                    end
                else
                    if test "$show_clean" = "true"
                        echo "✅ $current_branch - UP TO DATE"
                    end
                    set total_synced (math $total_synced + 1)
                end
        end
    end

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  ✅ Up to date: $total_synced"
    echo "  📤 Ahead: $total_ahead"

    if test "$fetch_only" = "true"
        echo "  📥 Behind: $total_behind (run without --fetch-only to pull)"
    else
        echo "  📥 Behind (pulled): $total_behind"
    end

    if test "$total_diverged" -gt 0
        echo "  ⚠️  Diverged: $total_diverged (needs manual merge)"
    end

    if test "$total_dirty" -gt 0
        echo "  ⚠️  Dirty: $total_dirty (commit or stash changes)"
    end

    if test "$total_no_remote" -gt 0
        echo "  📍 No remote: $total_no_remote"
    end

    echo ""

    # Recommendations
    set -l has_issues false

    if test "$total_diverged" -gt 0 -o "$total_dirty" -gt 0
        echo "💡 Recommendations:"
        if test "$total_dirty" -gt 0
            echo "  • Commit or stash changes in dirty worktrees"
        end
        if test "$total_diverged" -gt 0
            echo "  • Manually resolve diverged branches"
        end
        echo ""
    end

    if test "$total_dirty" -eq 0 -a "$total_diverged" -eq 0 -a "$total_behind" -eq 0
        echo "🎉 All worktrees are synced and up to date!"
        echo ""
    end
end
