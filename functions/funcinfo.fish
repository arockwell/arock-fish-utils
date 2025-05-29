function funcinfo --description 'List functions and optionally show source'
    set -l show_source false
    set -l pattern
    
    # Parse arguments
    for arg in $argv
        switch $arg
            case '-s' '--source'
                set show_source true
            case '*'
                set pattern $arg
        end
    end
    
    # Get matching functions
    set funcs (lsfunc $pattern)
    
    if test (count $funcs) -eq 0
        echo "No functions found"
        return 1
    end
    
    if test $show_source = true
        for func in $funcs
            set_color --bold cyan
            echo "=== $func ==="
            set_color normal
            functions $func
            echo
        end
    else
        # Just list the names
        printf '%s\n' $funcs
    end
end
