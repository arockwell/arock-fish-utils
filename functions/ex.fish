function ex
    # Directories to ignore by default (easy to modify)
    set -l ignored_dirs "wheels" "node_modules" ".git" "__pycache__" ".venv"
    
    set -l level ""
    set -l target ""
    set -l show_ignored false
    
    # Parse arguments
    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case "-l" "--level"
                set i (math $i + 1)
                if test $i -le (count $argv)
                    set level "--level=$argv[$i]"
                else
                    echo "Error: -l/--level requires a number"
                    return 1
                end
            case "-I" "--show-ignored"
                set show_ignored true
            case "-*"
                echo "Error: Unknown option $argv[$i]"
                return 1
            case "*"
                if test -z "$target"
                    set target "$argv[$i]"
                else
                    echo "Error: Too many arguments"
                    return 1
                end
        end
        set i (math $i + 1)
    end
    
    # Set up ignore patterns
    set -l ignore_flags
    if test "$show_ignored" = false
        # Join all ignored dirs with pipe separator
        set -l ignore_pattern (string join "|" $ignored_dirs)
        set ignore_flags "--ignore-glob=$ignore_pattern"
    end
    
    # Build eza command
    if test -z "$target"
        # No target specified, use current directory with tree
        if test -n "$level"
            eza --tree $level $ignore_flags
        else
            eza --tree $ignore_flags
        end
    else
        # Target specified - check if it's a directory
                if test -d "$target"
                        # It's a directory, use tree mode
            if test -n "$level"
                eza --tree $level $ignore_flags "$target"
            else
                eza --tree $ignore_flags "$target"
            end
        else
            # It's a file or doesn't exist, use regular eza
            eza $ignore_flags "$target"
        end
    end
end
