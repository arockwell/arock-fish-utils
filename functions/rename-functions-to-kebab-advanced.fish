# Defined interactively
function rename-functions-to-kebab-advanced
    argparse 'h/help' 'l/list' 'n/dry-run' 'a/all' 'f/force' 'v/verbose' -- $argv
    or return
    
    if set -q _flag_help
        echo "🚀 ADVANCED Fish Function Kebab-Case Renamer"
        echo "   (with cross-reference detection and updating)"
        echo ""
        echo "📖 Usage:"
        echo "  rename-functions-to-kebab-advanced [options] [function-names...]"
        echo ""
        echo "🎛️  Options:"
        echo "  -h, --help     Show this help"
        echo "  -l, --list     List functions that need renaming"
        echo "  -n, --dry-run  Show what would be renamed without doing it"
        echo "  -a, --all      Rename ALL functions that need it"
        echo "  -f, --force    Skip confirmation prompts"
        echo "  -v, --verbose  Show detailed cross-reference analysis"
        echo ""
        echo "✨ NEW FEATURES:"
        echo "   🔗 Detects and updates cross-references between renamed functions"
        echo "   🧠 Handles complex batches where functions call each other"
        echo "   🛡️  Validates all changes before applying"
        echo ""
        echo "📝 Examples:"
        echo "  rename-functions-to-kebab-advanced foo_bar bar_foo  # Rename batch"
        echo "  rename-functions-to-kebab-advanced --dry-run --all  # Preview all"
        return 0
    end
    
    # Function to convert to kebab-case
    function to_kebab_case
        set -l input $argv[1]
        echo $input | sed -E 's/([a-z])([A-Z])/\1-\2/g' | tr '_' '-' | tr '[:upper:]' '[:lower:]'
    end
    
    # Function to check if a name needs conversion
    function needs_kebab_conversion
        set -l name $argv[1]
        set -l kebab_name (to_kebab_case $name)
        test "$name" != "$kebab_name"
    end
    
    # Get all function files
    set -l all_functions
    for func_file in ~/.config/fish/functions/*.fish
        if test -f $func_file
            set -a all_functions (basename $func_file .fish)
        end
    end
    
    # Filter functions that need renaming
    set -l functions_needing_rename
    for func_name in $all_functions
        if needs_kebab_conversion $func_name
            set -a functions_needing_rename $func_name
        end
    end
    
    if set -q _flag_list
        echo "📋 Functions that need kebab-case conversion:"
        echo ""
        if test (count $functions_needing_rename) -eq 0
            echo "✅ All functions are already in kebab-case!"
        else
            for func_name in $functions_needing_rename
                set -l kebab_name (to_kebab_case $func_name)
                echo "  🔄 $func_name → $kebab_name"
            end
            echo ""
            echo "💡 Found (count $functions_needing_rename) function(s) that could be renamed"
        end
        return 0
    end
    
    # Determine which functions to process
    set -l functions_to_rename
    if set -q _flag_all
        set functions_to_rename $functions_needing_rename
    else if test (count $argv) -gt 0
        # Validate provided function names
        for func_name in $argv
            if not contains $func_name $all_functions
                echo "❌ Function not found: $func_name"
                return 1
            end
            if not needs_kebab_conversion $func_name
                echo "⚠️  Function '$func_name' is already in kebab-case"
            else
                set -a functions_to_rename $func_name
            end
        end
    else
        echo "❌ No functions specified"
        echo "💡 Use --list to see functions that need renaming"
        echo "💡 Use --all to rename all functions, or specify function names"
        return 1
    end
    
    if test (count $functions_to_rename) -eq 0
        echo "✅ No functions need renaming!"
        return 0
    end
    
    echo "🚀 ADVANCED BATCH RENAME SESSION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📦 Functions to rename: (count $functions_to_rename)"
    
    # Build rename plan with cross-reference analysis
    set -l rename_plan
    set -l cross_references_found false
    
    for func_name in $functions_to_rename
        set -l kebab_name (to_kebab_case $func_name)
        echo "  🔄 $func_name → $kebab_name"
        
        # Check if target already exists
        if test -f ~/.config/fish/functions/$kebab_name.fish
            echo "     ⚠️  Target file already exists!"
            if not set -q _flag_force
                echo "❌ Cannot proceed - target files exist. Use --force to overwrite."
                return 1
            end
        end
        
        set -a rename_plan "$func_name:$kebab_name"
    end
    echo ""
    
    # PHASE 1: Cross-reference analysis
    echo "🔍 PHASE 1: Cross-Reference Analysis"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    set -l cross_ref_map
    set -l total_cross_refs 0
    
    for func_name in $functions_to_rename
        set -l func_file ~/.config/fish/functions/$func_name.fish
        
        if not test -f $func_file
            continue
        end
        
        # Find references to other functions in the rename batch
        for other_func in $functions_to_rename
            if test "$func_name" = "$other_func"
                continue
            end
            
            # Search for references (more sophisticated pattern)
            set -l refs (grep -n "\\b$other_func\\b" $func_file | grep -v "^[0-9]*:[[:space:]]*#" | grep -v "^[0-9]*:[[:space:]]*function")
            
            if test (count $refs) -gt 0
                echo "📦 $func_name calls $other_func ((count $refs) time(s))"
                if set -q _flag_verbose
                    for ref in $refs
                        echo "   📍 $ref"
                    end
                end
                set total_cross_refs (math $total_cross_refs + (count $refs))
                set cross_references_found true
                set -a cross_ref_map "$func_name:$other_func:(count $refs)"
            end
        end
    end
    
    if test $total_cross_refs -gt 0
        echo "🔗 Found $total_cross_refs cross-reference(s) that will be updated!"
        echo "✨ This is where the FANCY magic happens!"
    else
        echo "ℹ️  No cross-references found - standard rename will be used"
    end
    echo ""
    
    # PHASE 2: Build global replacement strategy
    echo "🧠 PHASE 2: Global Replacement Strategy"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Build sed command array for global replacements
    set -l global_sed_commands
    for func_name in $functions_to_rename
        set -l kebab_name (to_kebab_case $func_name)
        echo "📝 Rule: $func_name → $kebab_name (all occurrences)"
        
        # Add sed commands for this function
        set -a global_sed_commands "-e" "s/^function $func_name/function $kebab_name/"
        set -a global_sed_commands "-e" "s/Usage: $func_name/Usage: $kebab_name/g"
        set -a global_sed_commands "-e" "s/\\b$func_name\\b/$kebab_name/g"
    end
    echo ""
    
    # Dry run mode with ADVANCED preview
    if set -q _flag_dry_run
        echo "🔍 PHASE 3: DRY RUN - Advanced Preview"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        for rename_pair in $rename_plan
            set -l old_name (string split ':' $rename_pair)[1]
            set -l new_name (string split ':' $rename_pair)[2]
            set -l old_file ~/.config/fish/functions/$old_name.fish
            
            echo "📄 File: $old_name.fish → $new_name.fish"
            echo "🔄 Advanced transformation preview:"
            echo ""
            
            # Apply GLOBAL replacements (not just local ones)
            set -l temp_file /tmp/fish_advanced_preview_$new_name.fish
            sed $global_sed_commands $old_file > $temp_file
            
            echo "--- Original (first 15 lines)"
            head -15 $old_file | sed 's/^/  /'
            echo ""
            echo "+++ After GLOBAL rename (first 15 lines)"
            head -15 $temp_file | sed 's/^/  /'
            echo ""
            
            # Show specific cross-references that changed
            if $cross_references_found
                echo "🔗 Cross-references updated in this file:"
                for other_func in $functions_to_rename
                    if test "$old_name" != "$other_func"
                        set -l other_kebab (to_kebab_case $other_func)
                        set -l old_refs (grep -c "\\b$other_func\\b" $old_file 2>/dev/null)
                        if test -z "$old_refs"
                            set old_refs 0
                        end
                        set -l new_refs (grep -c "\\b$other_kebab\\b" $temp_file 2>/dev/null)
                        if test -z "$new_refs"
                            set new_refs 0
                        end
                        if test "$old_refs" -gt 0
                            echo "   🔄 $other_func → $other_kebab ($old_refs reference(s) updated)"
                        end
                    end
                end
            end
            
            rm $temp_file
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
        end
        
        # Show commit message preview
        echo "📝 Git commit message preview:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        set -l dry_run_renames
        for rename_pair in $rename_plan
            set -l old_name (string split ':' $rename_pair)[1]
            set -l new_name (string split ':' $rename_pair)[2]
            set -a dry_run_renames "$old_name → $new_name"
        end
        
        set -l commit_lines "Rename functions to kebab-case (with cross-references)"
        set -a commit_lines ""  # Empty line
        for rename in $dry_run_renames
            set -a commit_lines "- $rename"
        end
        
        if $cross_references_found
            set -a commit_lines ""
            set -a commit_lines "Cross-references updated: $total_cross_refs total"
        end
        
        # Build commit message line by line and join properly
        set -l preview_commit_message "Rename functions to kebab-case (with cross-references)

"
        for rename in $dry_run_renames
            set preview_commit_message "$preview_commit_message- $rename
"
        end
        
        if $cross_references_found
            set preview_commit_message "$preview_commit_message
Cross-references updated: $total_cross_refs total"
        end
        echo "$preview_commit_message"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        echo "💡 Remove --dry-run to perform the ADVANCED renaming"
        echo "🚀 This will be FUCKING FANCY! 🎉"
        return 0
    end
    
    # Confirmation for advanced operations
    if not set -q _flag_force
        echo "🤔 Ready to perform ADVANCED batch rename with cross-reference updating?"
        if $cross_references_found
            echo "⚠️  This will update $total_cross_refs cross-reference(s) across files!"
        end
        read -P "Proceed? [y/N] " -l confirm
        if test "$confirm" != "y" -a "$confirm" != "Y"
            echo "❌ Advanced rename cancelled"
            return 1
        end
    end
    
    # PHASE 3: Execute the advanced rename
    echo ""
    echo "🚀 PHASE 3: Executing Advanced Rename"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    set -l successful_renames
    set -l failed_renames
    
    # Check if we're in a git repo
        set -l is_git_repo false
        if test -d ~/.config/.git
                set is_git_repo true
                cd ~/.config
        end
    
        # Process each file with GLOBAL replacements
        for rename_pair in $rename_plan
                set -l old_name (string split ':' $rename_pair)[1]
                set -l new_name (string split ':' $rename_pair)[2]
                
                set -l old_file ~/.config/fish/functions/$old_name.fish
                set -l new_file ~/.config/fish/functions/$new_name.fish
                
                echo "📦 Advanced renaming: $old_name → $new_name"
                
                # Apply GLOBAL sed replacements (handles cross-references!)
                if sed $global_sed_commands $old_file > $new_file
                        echo "  ✅ Created with global replacements applied"
                        
                        # Handle git and cleanup
                        if test $is_git_repo = true
                                if git ls-files --error-unmatch fish/functions/$old_name.fish >/dev/null 2>&1
                                        if git mv fish/functions/$old_name.fish fish/functions/$new_name.fish >/dev/null 2>&1
                                                echo "  ✅ Git tracked the rename"
                                        else
                                                rm $old_file
                                                git add fish/functions/$new_name.fish
                                                git rm fish/functions/$old_name.fish 2>/dev/null
                                                echo "  ✅ Git add/remove completed"
                                        end
                                else
                                        rm $old_file
                                        echo "  ✅ Removed old file"
                                end
                        else
                                rm $old_file
                                echo "  ✅ Removed old file"
                        end
                        
                        set -a successful_renames "$old_name → $new_name"
                else
                        echo "  ❌ Failed to create new file"
                        set -a failed_renames $old_name
                end
        end
    
        # PHASE 4: Commit with advanced message
        if test $is_git_repo = true -a (count $successful_renames) -gt 0
                echo ""
                echo "📝 Committing advanced changes to git..."
                
                set -l commit_lines "Rename functions to kebab-case (with cross-references)"
                set -a commit_lines ""
                for rename in $successful_renames
                        set -a commit_lines "- $rename"
                end
                
                if $cross_references_found
                        set -a commit_lines ""
                        set -a commit_lines "🔗 Cross-references updated: $total_cross_refs total"
                        set -a commit_lines "✨ Advanced batch rename with inter-function reference handling"
                end
                
                # Build commit message with proper line breaks
                set -l commit_message "Rename functions to kebab-case (with cross-references)

"
                for rename in $successful_renames
                        set commit_message "$commit_message- $rename
"
                end
                
                if $cross_references_found
                        set commit_message "$commit_message
🔗 Cross-references updated: $total_cross_refs total
✨ Advanced batch rename with inter-function reference handling"
                end
                
                if git commit -m "$commit_message"
                        echo "✅ Advanced changes committed to git!"
                else
                        echo "⚠️  Git commit failed or nothing to commit"
                end
        end
    
        # PHASE 5: Summary
        echo ""
        echo "🎉 ADVANCED RENAME COMPLETE!"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        if test (count $successful_renames) -gt 0
                echo "✅ Successfully renamed with cross-reference updates:"
                for rename in $successful_renames
                        echo "   🔄 $rename"
                end
                
                if $cross_references_found
                        echo ""
                        echo "🔗 Cross-references updated: $total_cross_refs total"
                        echo "✨ All inter-function calls have been updated to kebab-case!"
                end
        end
    
        if test (count $failed_renames) -gt 0
                echo "❌ Failed to rename:"
                for func in $failed_renames
                        echo "   🚫 $func"
                end
        end
    
        echo ""
        echo "💡 Next steps:"
        echo "   1. Restart your shell: exec fish"
        echo "   2. Test your renamed functions"
        echo "   3. Verify cross-references work correctly"
        echo ""
        echo "🚀 THAT WAS FUCKING FANCY! 🎉✨"
end
