function claude-auto
    # Check if claude command exists
    if not command -v claude >/dev/null 2>&1
        echo "Error: claude command not found. Make sure Claude Code is installed and in your PATH."
        return 1
    end
    
    # Check if arguments were provided
    if test (count $argv) -eq 0
        echo "Usage: claude-auto <task_description> [files...]"
        echo "Example: claude-auto 'create a hello world python script'"
        echo "Example: claude-auto 'refactor this code @main.py'"
        echo "Example: claude-auto 'review code' main.py utils.py"
        echo ""
        echo "Shows real-time streaming output by default"
        return 1
    end
    
    # Parse arguments - first is prompt, rest are explicit files
    set prompt $argv[1]
    set explicit_files $argv[2..-1]
    
    # Handle @filename syntax - fix spacing and formatting
    while string match -q '*@*' $prompt
        set filename (string match -r '@([^\s]+)' $prompt)[2]
        if test -n "$filename"
            if test -f $filename
                set content (cat $filename)
                set replacement "

Here is the content of $filename:

```
$content
```"
                set prompt (string replace "@$filename" $replacement $prompt)
                echo "Included file: $filename" >&2
            else
                echo "Warning: File $filename not found" >&2
                set prompt (string replace "@$filename" "[File not found: $filename]" $prompt)
            end
        else
            break
        end
    end
    
    # Handle explicit file arguments
    for file in $explicit_files
        if test -f $file
            set prompt "$prompt

File: $file
```
(cat $file)
```
"
        else
            echo "Warning: File $file not found" >&2
        end
    end
    
    # Debug: show final prompt (remove this line once working)
    echo "Final prompt being sent to claude:" >&2
    echo "---" >&2
    echo $prompt >&2
    echo "---" >&2
    
    # Build command with streaming by default
    set cmd_args "-p" $prompt "--allowedTools" "Read,Write,Edit,Create,Bash" "--output-format" "stream-json" "--verbose"
    
    # Always pipe through our pretty parser
    claude $cmd_args | claude-pretty-parser
end
