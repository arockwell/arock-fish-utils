# Defined interactively
function migrate-fish-functions
    argparse 'h/help' 'l/list' 'a/all' 'n/dry-run' -- $argv
    or return
    
    if set -q _flag_help
        echo "🐟 Fish Function Migrator"
        echo ""
        echo "📖 Usage:"
        echo "  migrate-fish-functions [options] <plugin-directory> [function-names...]"
        echo ""
        echo "🎛️  Options:"
        echo "  -h, --help     Show this help"
        echo "  -l, --list     List all available functions in config"
        echo "  -a, --all      Migrate ALL functions (use with caution!)"
        echo "  -n, --dry-run  Show what would be migrated without doing it"
        echo ""
        echo "📝 Examples:"
        echo "  migrate-fish-functions ~/dev/my-plugin mkcd extract    # Migrate specific functions"
        echo "  migrate-fish-functions --list                          # List available functions"
        echo "  migrate-fish-functions --dry-run ~/dev/my-plugin mkcd  # Preview migration"
        echo "  migrate-fish-functions --all ~/dev/my-plugin           # Migrate everything"
        return 0
    end
    
    if set -q _flag_list
        echo "📋 Available functions in ~/.config/fish/functions/:"
        echo ""
        for func_file in ~/.config/fish/functions/*.fish
            if test -f $func_file
                set -l func_name (basename $func_file .fish)
                echo "  🐟 $func_name"
            end
        end
        echo ""
        echo "💡 Use: migrate-fish-functions <plugin-dir> <function-name> [function-name...]"
        return 0
    end
    
    # Check if plugin directory was provided
    if test (count $argv) -eq 0
        echo "❌ Error: Plugin directory required"
        echo "💡 Usage: migrate-fish-functions <plugin-directory> [function-names...]"
        echo "💡 Use --help for more options"
        return 1
    end
    
    set -l plugin_dir $argv[1]
    set -l functions_to_migrate $argv[2..-1]
    
    # Check if plugin directory exists
    if not test -d $plugin_dir
        echo "❌ Plugin directory not found: $plugin_dir"
        return 1
    end
    
    # Create functions directory if it doesn't exist
        if not test -d $plugin_dir/functions
                echo "📁 Creating functions directory in plugin"
                mkdir -p $plugin_dir/functions
        end
    
        # If --all flag is set, migrate all functions
        if set -q _flag_all
                echo "⚠️  You're about to migrate ALL functions from your config!"
                read -P "🤔 Are you sure? This will move everything! [y/N] " -l confirm
                if test "$confirm" != "y" -a "$confirm" != "Y"
                        echo "❌ Migration cancelled"
                        return 1
                end
                
                set functions_to_migrate
                for func_file in ~/.config/fish/functions/*.fish
                        if test -f $func_file
                                set -a functions_to_migrate (basename $func_file .fish)
                        end
                end
        end
    
        # Check if we have functions to migrate
        if test (count $functions_to_migrate) -eq 0
                echo "❌ No functions specified to migrate"
                echo "💡 Use --list to see available functions"
                echo "💡 Usage: migrate-fish-functions <plugin-dir> <function-name> [function-name...]"
                return 1
        end
    
        # Validate all functions exist before starting
        set -l missing_functions
        for func_name in $functions_to_migrate
                if not test -f ~/.config/fish/functions/$func_name.fish
                        set -a missing_functions $func_name
                end
        end
    
        if test (count $missing_functions) -gt 0
                echo "❌ The following functions were not found:"
                for func in $missing_functions
                        echo "   🚫 $func"
                end
                return 1
        end
    
        # Show what will be migrated
        echo "🚀 Planning to migrate (count $functions_to_migrate) function(s):"
        for func_name in $functions_to_migrate
                echo "  📦 $func_name"
                
                # Check if already exists in plugin
                if test -f $plugin_dir/functions/$func_name.fish
                        echo "     ⚠️  (will overwrite existing)"
                end
        end
        echo ""
    
        # Dry run mode
        if set -q _flag_dry_run
                echo "🔍 Dry run - no files would be moved"
                echo "💡 Remove --dry-run to perform the migration"
                return 0
        end
    
        # Confirm migration
        if not set -q _flag_all  # Don't ask again if we already confirmed for --all
                read -P "🤔 Proceed with migration? [y/N] " -l confirm
                if test "$confirm" != "y" -a "$confirm" != "Y"
                        echo "❌ Migration cancelled"
                        return 1
                end
        end
    
        # Track successful migrations
        set -l successful_migrations
        set -l failed_migrations
    
        # Migrate each function
        for func_name in $functions_to_migrate
                echo ""
                echo "📦 Migrating: $func_name"
                
                set -l config_path ~/.config/fish/functions/$func_name.fish
                set -l plugin_path $plugin_dir/functions/$func_name.fish
                
                # Copy to plugin
                if cp $config_path $plugin_path
                        echo "  ✅ Copied to plugin"
                        
                        # Remove from config
                        if rm $config_path
                                echo "  ✅ Removed from config"
                                set -a successful_migrations $func_name
                        else
                                echo "  ❌ Failed to remove from config"
                                set -a failed_migrations $func_name
                                # Cleanup: remove the copied file
                                rm $plugin_path 2>/dev/null
                        end
                else
                        echo "  ❌ Failed to copy to plugin"
                        set -a failed_migrations $func_name
                end
        end
    
        # Commit changes if repositories exist
        echo ""
        echo "📝 Committing changes..."
    
        # Commit config changes
        if test -d ~/.config/fish/.git
                echo "🔧 Committing config repository..."
                cd ~/.config/fish
                git add -A
                if git commit -m "Migrate functions to plugin: (string join ', ' $successful_migrations)"
                        echo "  ✅ Config changes committed"
                else
                        echo "  ⚠️  Config commit failed or nothing to commit"
                end
        end
    
        # Commit plugin changes
        if test -d $plugin_dir/.git
                echo "🔧 Committing plugin repository..."
                cd $plugin_dir
                git add functions/
                if git commit -m "Add migrated functions: (string join ', ' $successful_migrations)"
                        echo "  ✅ Plugin changes committed"
                else
                        echo "  ⚠️  Plugin commit failed or nothing to commit"
                end
        end
    
        # Summary
        echo ""
        echo "🎉 Migration Summary:"
        if test (count $successful_migrations) -gt 0
                echo "✅ Successfully migrated:"
                for func in $successful_migrations
                        echo "   🐟 $func"
                end
        end
    
        if test (count $failed_migrations) -gt 0
                echo "❌ Failed to migrate:"
                for func in $failed_migrations
                        echo "   🚫 $func"
                end
        end
    
        echo ""
        echo "💡 Next steps:"
        echo "   1. Test your plugin: fisher install $plugin_dir"
        echo "   2. Restart your shell or run: exec fish"
        echo "   3. Test your migrated functions"
        
        if test (count $successful_migrations) -gt 0
                echo ""
                echo "🔄 Your functions are now part of your plugin!"
        end
end
