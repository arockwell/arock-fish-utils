#!/usr/bin/env fish
# git-worktree-status - Quick visual status of all worktrees

function git-worktree-status --description "Show one-line status for all worktrees"
    # Check if we're in a git repository
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "❌ Not in a git repository"
        return 1
    end

    # Parse arguments
    set -l show_clean false
    set -l compact false

    for arg in $argv
        switch $arg
            case -a --all
                set show_clean true
            case -c --compact
                set compact true
            case -h --help
                echo "Usage: git-worktree-status [OPTIONS]"
                echo ""
                echo "Show quick one-line status for all worktrees."
                echo ""
                echo "Options:"
                echo "  -a, --all       Show all worktrees including clean ones"
                echo "  -c, --compact   Ultra-compact emoji-only mode"
                echo "  -h, --help      Show this help message"
                echo ""
                echo "Status Indicators:"
                echo "  ✅  Clean and up-to-date"
                echo "  📝  Uncommitted changes"
                echo "  📤  Unpushed commits"
                echo "  📥  Behind remote"
                echo "  ⚠️   Diverged from remote"
                echo "  📍  No remote tracking"
                echo ""
                echo "Examples:"
                echo "  git-worktree-status           # Show worktrees with changes"
                echo "  git-worktree-status --all     # Show all worktrees"
                echo "  git-worktree-status --compact # Emoji-only output"
                return 0
        end
    end

    set -l main_branch (git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    if test -z "$main_branch"
        set main_branch "main"
    end

    if test "$compact" = "false"
        echo "Git Worktree Status"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    end

    # Parse worktrees
    set -l current_path ""
    set -l current_branch ""
    set -l has_output false

    git worktree list --porcelain | while read -l line
        switch $line
            case 'worktree *'
                set current_path (string split ' ' -- $line)[2]
            case 'branch *'
                set current_branch (string replace 'branch refs/heads/' '' -- $line)

                if not test -d "$current_path"
                    if test "$compact" = "true"
                        echo "💥 $current_branch"
                    else
                        printf "💥  %-30s BROKEN\n" $current_branch
                    end
                    set has_output true
                    continue
                end

                # Get upstream
                set -l upstream (git -C "$current_path" rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)

                # Check working directory status
                set -l status_output (git -C "$current_path" status --short 2>/dev/null)
                set -l is_dirty (echo "$status_output" | wc -l | string trim)

                # Get ahead/behind if has upstream
                set -l ahead 0
                set -l behind 0
                set -l has_upstream false

                if test -n "$upstream"
                    set has_upstream true
                    set ahead (git -C "$current_path" rev-list --count $upstream..HEAD 2>/dev/null)
                    set behind (git -C "$current_path" rev-list --count HEAD..$upstream 2>/dev/null)
                end

                # Determine status emoji and message
                set -l emoji ""
                set -l status_msg ""
                set -l show_this false

                if test "$is_dirty" -gt 0
                    set emoji "📝"
                    set status_msg "$is_dirty changes"
                    set show_this true
                else if test "$has_upstream" = "false"
                    set emoji "📍"
                    set status_msg "no remote"
                    set show_this true
                else if test "$ahead" -gt 0 -a "$behind" -gt 0
                    set emoji "⚠️ "
                    set status_msg "↑$ahead ↓$behind"
                    set show_this true
                else if test "$ahead" -gt 0
                    set emoji "📤"
                    set status_msg "↑$ahead"
                    set show_this true
                else if test "$behind" -gt 0
                    set emoji "📥"
                    set status_msg "↓$behind"
                    set show_this true
                else
                    set emoji "✅"
                    set status_msg "up to date"
                    if test "$show_clean" = "true"
                        set show_this true
                    end
                end

                # Output if needed
                if test "$show_this" = "true"
                    set has_output true

                    if test "$compact" = "true"
                        # Compact mode: just emoji and branch
                        echo "$emoji $current_branch"
                    else
                        # Full mode: emoji, branch (30 chars), status message
                        set -l short_branch (string sub -l 28 $current_branch)
                        printf "%s  %-30s %s\n" $emoji $short_branch $status_msg
                    end
                end
        end
    end

    if test "$has_output" = "false"
        if test "$compact" = "true"
            echo "✅ All clean"
        else
            echo "✅  All worktrees are clean and up to date!"
        end
    end
end
