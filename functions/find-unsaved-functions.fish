function find-unsaved-functions --description "Find user-defined functions that aren't saved to disk"
    set -l temp_dir (mktemp -d)
    set -l current_functions "$temp_dir/current.txt"
    set -l saved_functions "$temp_dir/saved.txt"
    set -l builtin_functions "$temp_dir/builtin.txt"
    
    # Get all currently defined functions
    functions -n | sort > $current_functions
    
    # Get built-in and system functions by checking what exists in a fresh Fish session
    # We'll use common Fish built-ins and system functions as a baseline
        printf '%s\n' \
                N_ abbr alias bg cd cdh contains_seq diff dirh dirs disown \
                down-or-search edit_command_buffer export fg fish_add_path \
                fish_breakpoint_prompt fish_clipboard_copy fish_clipboard_paste \
                fish_command_not_found fish_commandline_append fish_commandline_prepend \
                fish_config fish_default_key_bindings fish_default_mode_prompt \
                fish_delta fish_fossil_prompt fish_git_prompt fish_greeting \
                fish_hg_prompt fish_hybrid_key_bindings fish_is_root_user \
                fish_job_summary fish_mode_prompt fish_opt fish_print_git_action \
                fish_print_hg_root fish_prompt fish_sigtrap_handler \
                fish_status_to_signal fish_svn_prompt fish_title \
                fish_update_completions fish_vcs_prompt fish_vi_cursor \
                fish_vi_key_bindings funced funcsave grep help history isatty \
                kill la ll ls man nextd nextd-or-forward-token open popd prevd \
                prevd-or-backward-token prompt_hostname prompt_login prompt_pwd \
                psub pushd realpath seq setenv suspend trap umask up-or-search \
                vared wait | sort > $builtin_functions
        
        # Get user-saved functions from config directories
        set -l config_dirs $__fish_config_dir ~/.config/fish
        
        # Find all .fish files and extract function names
        for dir in $config_dirs
                if test -d $dir/functions
                        find $dir/functions -name "*.fish" -type f | while read file
                                basename $file .fish
                        end
                end
                # Also check for functions defined in config.fish
                if test -f $dir/config.fish
                        grep "^[[:space:]]*function " "$dir/config.fish" 2>/dev/null | sed 's/^[[:space:]]*function \([a-zA-Z0-9_-]*\).*/\1/'
                end
        end | sort -u > $saved_functions
        
        # Remove built-ins from current functions, then find what's not saved
    set -l user_functions (comm -23 $current_functions $builtin_functions)
    set -l unsaved
    
    # Check each user function to see if it's saved
        for func in $user_functions
                if not grep -q "^$func\$" $saved_functions
                        set -a unsaved $func
                end
        end
        
        if test (count $unsaved) -eq 0
                echo "No unsaved user-defined functions found."
        else
                echo "Unsaved user-defined functions:"
                for func in $unsaved
                        echo "  $func"
                        # Show a preview of the function
                        echo "    $(functions $func | head -n 1 | string trim)"
                end
                
                echo
                echo "To save a function, use:"
                echo "  funcsave function_name"
                echo
                echo "To see full function definition:"
                echo "  functions function_name"
        end
        
        # Cleanup
        rm -rf $temp_dir
end
