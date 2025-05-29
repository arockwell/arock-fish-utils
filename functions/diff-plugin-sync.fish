# Defined interactively
function diff-plugin-sync
    argparse 'h/help' 'p/plugin-dir=' 'v/verbose' 'f/function=' 'c/context=' -- $argv
    or return
    
    if set -q _flag_help
        echo "🔍 Plugin Sync Diff Viewer"
        echo ""
        echo "📖 Usage:"
        echo "  diff-plugin-sync [options] [function-name]"
        echo ""
        echo "🎛️  Options:"
        echo "  -h, --help              Show this help"
        echo "  -p, --plugin-dir DIR    Plugin directory (default: auto-detect)"
        echo "  -f, --function FUNC     Show diff for specific function only"
        echo "  -c, --context NUM       Number of context lines (default: 3)"
        echo "  -v, --verbose           Show file timestamps and sizes"
        echo ""
        echo "📝 Examples:"
        echo "  diff-plugin-sync                        # Show all diffs"
        echo "  diff-plugin-sync -f ex.fish            # Diff specific function"
        echo "  diff-plugin-sync -c 5                  # More context lines"
        echo "  diff-plugin-sync --verbose             # Show file details"
        return 0
    end
    
    # Auto-detect plugin directory if not specified
    set -l plugin_dir
    if set -q _flag_plugin_dir
        set plugin_dir $_flag_plugin_dir
    else
        set -l potential_dirs
        set -a potential_dirs (pwd)
        set -a potential_dirs ~/dev/*-fish-*
        set -a potential_dirs ~/dev/*-utils
        
        for dir in $potential_dirs
            if test -d "$dir/functions" -a -f "$dir/conf.d/"*.fish -a "$dir" != "$HOME/.config/fish"
                set plugin_dir $dir
                break
            end
        end
        
        if test -z "$plugin_dir"
            echo "❌ Could not auto-detect plugin directory"
            echo "💡 Use -p/--plugin-dir to specify your plugin directory"
            return 1
        end
    end
    
    # Validate plugin directory
    if not test -d $plugin_dir
        echo "❌ Plugin directory not found: $plugin_dir"
        return 1
    end
    
    if not test -d $plugin_dir/functions
        echo "❌ No functions/ directory found in: $plugin_dir"
        return 1
    end
    
    set -l context_lines 3
    if set -q _flag_context
        set context_lines $_flag_context
    end
    
    echo "🔍 Diffing plugin functions: $plugin_dir"
    echo ""
    
    set -l plugin_functions
    set -l out_of_sync_functions
    set -l diffs_shown 0
    
    # Get all functions from plugin or specific function
    if set -q _flag_function
        set plugin_functions $_flag_function
    else
        for func_file in $plugin_dir/functions/*.fish
            if test -f $func_file
                set -a plugin_functions (basename $func_file)
            end
        end
    end
    
    if test (count $plugin_functions) -eq 0
        echo "⚠️  No functions found to diff"
        return 0
    end
    
    # Check each function for differences
    for func_file in $plugin_functions
        set -l plugin_file $plugin_dir/functions/$func_file
        set -l config_file ~/.config/fish/functions/$func_file
        
        if not test -f $plugin_file
            echo "❌ Plugin function not found: $func_file"
            continue
        end
        
        if not test -f $config_file
            echo "❌ Config function not found: $func_file"
            continue
        end
        
        # Check if files are different
        if not diff -q $plugin_file $config_file >/dev/null 2>&1
            set -a out_of_sync_functions $func_file
            
            echo "🔄 DIFF: $func_file"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            
            if set -q _flag_verbose
                # Show file details
                set -l plugin_mtime (stat -f %m $plugin_file 2>/dev/null)
                set -l config_mtime (stat -f %m $config_file 2>/dev/null)
                set -l plugin_size (stat -f %z $plugin_file 2>/dev/null)
                set -l config_size (stat -f %z $config_file 2>/dev/null)
                
                echo "📄 Plugin: $plugin_file"
                echo "   📅 Modified: "(date -r $plugin_mtime "+%Y-%m-%d %H:%M:%S")
                echo "   📏 Size: $plugin_size bytes"
                echo ""
                echo "📄 Config: $config_file"
                echo "   📅 Modified: "(date -r $config_mtime "+%Y-%m-%d %H:%M:%S")
                echo "   📏 Size: $config_size bytes"
                echo ""
            end
            
            # Show the actual diff
            echo "📝 Changes (Plugin → Config):"
            
            # Use colordiff if available, otherwise regular diff
            if command -q colordiff
                colordiff -u --label "Plugin/$func_file" --label "Config/$func_file" -C $context_lines $plugin_file $config_file
            else
                diff -u --label "Plugin/$func_file" --label "Config/$func_file" -C $context_lines $plugin_file $config_file
            end
            
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            
            set diffs_shown (math $diffs_shown + 1)
        else
            if set -q _flag_function
                echo "✅ No differences found in: $func_file"
            end
        end
    end
    
    # Summary
    if test $diffs_shown -eq 0
        if set -q _flag_function
            echo "✅ Function is in sync: $_flag_function"
        else
            echo "✅ All functions are in sync!"
        end
    else
        echo "📊 DIFF SUMMARY:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🔄 Functions with differences: $diffs_shown"
        
        for func in $out_of_sync_functions
            echo "   📦 $func"
        end
        
        echo ""
        echo "💡 To sync config → plugin:"
        echo "   cp ~/.config/fish/functions/{$func_file} $plugin_dir/functions/"
        echo ""
        echo "💡 To sync plugin → config:"
        echo "   fisher install $plugin_dir"
    end
end
