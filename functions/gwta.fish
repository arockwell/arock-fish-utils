function gwta --description 'make branch and switch to the worktree'
    if test (count $argv) -eq 0
        echo "Usage: gwta <branch-name>"
        return 1
    end
    
    set branch_name $argv[1]
    git branch $branch_name
    
    # Get the main worktree path to extract project name
    set main_worktree (git worktree list | head -n1 | awk '{print $1}')
    set project_name (basename $main_worktree)
    
    # Smart worktree path detection
    if test -d ../worktrees
        # If worktrees directory exists, use it with project prefix
        set worktree_path ../worktrees/$project_name-$branch_name
    else
        # Otherwise use sibling directory
        set worktree_path ../$branch_name
    end
    
    git worktree add $worktree_path $branch_name
    cd $worktree_path
end
