#!/usr/bin/env fish
# gwp - Git Worktree Path (print path without switching)

function gwp --description "Print worktree path for a branch (useful for scripts)"
    # Check if we're in a git repository
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "❌ Not in a git repository" >&2
        return 1
    end

    # Parse arguments
    set -l query ""
    set -l exact_match false

    for arg in $argv
        switch $arg
            case -e --exact
                set exact_match true
            case -h --help
                echo "Usage: gwp [BRANCH_NAME] [OPTIONS]"
                echo ""
                echo "Print the path to a worktree by branch name (without switching to it)."
                echo "Useful for scripts, aliases, and quick operations."
                echo ""
                echo "Arguments:"
                echo "  BRANCH_NAME      Branch name to find (fuzzy match by default)"
                echo ""
                echo "Options:"
                echo "  -e, --exact      Require exact branch name match"
                echo "  -h, --help       Show this help message"
                echo ""
                echo "Examples:"
                echo "  gwp main                    # Print path to main worktree"
                echo "  gwp feature/auth            # Find feature/auth worktree"
                echo "  gwp feature                 # Fuzzy match (returns first match)"
                echo "  cd \$(gwp feature)           # cd to feature worktree"
                echo "  code \$(gwp pr-123)          # Open worktree in VS Code"
                echo "  git -C \$(gwp main) status   # Run git command in worktree"
                echo ""
                echo "Exit codes:"
                echo "  0 - Worktree found"
                echo "  1 - Not in git repo or worktree not found"
                return 0
            case '*'
                set query $arg
        end
    end

    # If no query, show error
    if test -z "$query"
        echo "Error: Branch name required" >&2
        echo "Usage: gwp BRANCH_NAME" >&2
        echo "Try 'gwp --help' for more information" >&2
        return 1
    end

    # Parse worktrees
    set -l found_path ""
    set -l current_path ""
    set -l current_branch ""

    git worktree list --porcelain | while read -l line
        switch $line
            case 'worktree *'
                set current_path (string split ' ' -- $line)[2]
            case 'branch *'
                set current_branch (string replace 'branch refs/heads/' '' -- $line)

                # Check for match
                if test "$exact_match" = "true"
                    # Exact match
                    if test "$current_branch" = "$query"
                        echo $current_path
                        return 0
                    end
                else
                    # Fuzzy match (contains)
                    if string match -q "*$query*" -- $current_branch
                        echo $current_path
                        return 0
                    end
                end
        end
    end

    # If we get here, no match found
    echo "Error: No worktree found for branch '$query'" >&2
    return 1
end
