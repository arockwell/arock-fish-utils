# Defined interactively
function plugin-funcsave-and-commit
    argparse 'h/help' 'p/plugin-dir=' -- $argv
    or return
    
    if set -q _flag_help
        echo "🐟 Plugin Function Save and Commit"
        echo ""
        echo "📖 Usage:"
        echo "  plugin-funcsave-and-commit [options] <function-name> [commit-message]"
        echo ""
        echo "🎛️  Options:"
        echo "  -h, --help              Show this help"
        echo "  -p, --plugin-dir DIR    Specify plugin directory (default: auto-detect)"
        echo ""
        echo "📝 Examples:"
        echo "  plugin-funcsave-and-commit my-function              # Auto-detect plugin dir"
        echo "  plugin-funcsave-and-commit my-function 'Add utils'  # With custom message"
        echo "  plugin-funcsave-and-commit -p ~/dev/my-plugin func  # Specify plugin dir"
        echo ""
        echo "💡 This function:"
        echo "   1. Takes your currently loaded function from memory"
        echo "   2. Saves it to your plugin's functions/ directory"
        echo "   3. Commits it to the plugin's git repository"
        return 0
    end
    
    # Check if function name is provided
    if test (count $argv) -eq 0
        echo "❌ Usage: plugin-funcsave-and-commit <function-name> [commit-message]"
        return 1
    end
    
    set -l function_name $argv[1]
    set -l commit_msg $argv[2]
    
    # Check if function exists in memory
    if not functions -q $function_name
        echo "❌ Function '$function_name' not found in memory"
        echo "💡 Make sure the function is loaded. Try: funced $function_name"
        return 1
    end
    
    # Auto-detect plugin directory if not specified
    set -l plugin_dir
    if set -q _flag_plugin_dir
        set plugin_dir $_flag_plugin_dir
    else
        # Try to auto-detect plugin directory
        # Look for directories with functions/ subdirectory in common locations
        set -l potential_dirs
        set -a potential_dirs (pwd)  # Current directory
        set -a potential_dirs ~/dev/*-fish-*  # Common fish plugin naming
        set -a potential_dirs ~/dev/*-utils   # Utils plugins
        set -a potential_dirs ~/.local/share/fish-plugins/*  # Local fish plugins
        
        for dir in $potential_dirs
            if test -d "$dir/functions" -a -d "$dir/.git"
                set plugin_dir $dir
                break
            end
        end
        
        if test -z "$plugin_dir"
            echo "❌ Could not auto-detect plugin directory"
            echo "💡 Use -p/--plugin-dir to specify your plugin directory"
            echo "💡 Or run this command from within your plugin directory"
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
        echo "💡 This doesn't look like a Fish plugin directory"
        return 1
    end
    
    if not test -d $plugin_dir/.git
        echo "❌ Plugin directory is not a git repository: $plugin_dir"
        return 1
    end
    
    # Set default commit message
    if test -z "$commit_msg"
        set commit_msg "✨ Add/update function: $function_name"
    end
    
    set -l function_file "$plugin_dir/functions/$function_name.fish"
    set -l original_dir (pwd)
    
    echo "🚀 Saving function to plugin:"
    echo "   📦 Function: $function_name"
    echo "   📂 Plugin: $plugin_dir"
    echo "   📄 File: functions/$function_name.fish"
    
    # Get function definition from memory and save to plugin
    if functions $function_name > $function_file
        echo "✅ Function saved to plugin"
    else
        echo "❌ Failed to save function to plugin"
        return 1
    end
    
    # Change to plugin directory for git operations
    cd $plugin_dir
    
    # Add the function file to git
    git add "functions/$function_name.fish"
    if test $status -ne 0
        echo "❌ Failed to add function file to git"
        cd $original_dir
        return 1
    end
    
    # Check if there are changes to commit
    if git diff --staged --quiet
        echo "⚠️  No changes to commit (function may be identical)"
        cd $original_dir
        return 0
    end
    
    # Commit the changes
    if git commit -m "$commit_msg"
        echo "🎉 Successfully committed function to plugin!"
        echo "💡 Function '$function_name' is now part of your plugin"
    else
        echo "❌ Failed to commit function"
        cd $original_dir
        return 1
    end
    
    # Show git status
    echo ""
    echo "📊 Plugin repository status:"
    git status --short
    
    # Return to original directory
    cd $original_dir
    
    echo ""
    echo "🔄 Next steps:"
    echo "   1. Test your plugin: fisher install $plugin_dir"
    echo "   2. Push changes: cd $plugin_dir && git push"
    echo "   3. Update plugin documentation if needed"
end
