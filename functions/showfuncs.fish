function showfuncs --description 'Show source of functions matching pattern'
    # Get the matching function names using lsfunc
    set matching_funcs (lsfunc $argv[1])
    
    # If lsfunc returned nothing, exit
    if test (count $matching_funcs) -eq 0
        echo "No functions found matching pattern: $argv[1]"
        return 1
    end
    
    # Show source for each function
    for func in $matching_funcs
        set_color --bold cyan
        echo "=== $func ==="
        set_color normal
        functions $func
        echo
    end
end
