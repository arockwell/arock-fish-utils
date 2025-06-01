function claude-pretty-parser
    while read -l line
        # Get current timestamp
        set timestamp (date '+%H:%M:%S')
        
        # Check if we have jq available for JSON parsing
        if not command -v jq >/dev/null 2>&1
            echo "[$timestamp] $line"
            continue
        end
        
        # Parse the JSON and extract key information
        set msg_type (echo $line | jq -r '.type // ""')
        
        switch $msg_type
            case "system"
                set subtype (echo $line | jq -r '.subtype // ""')
                if test "$subtype" = "init"
                    echo "[$timestamp] 🚀 Claude Code session started"
                    set tools (echo $line | jq -r '.tools[]?' | string join ', ')
                    echo "[$timestamp] 📋 Available tools: $tools"
                end
                
            case "assistant"
                set content (echo $line | jq -r '.message.content[]? | select(.type == "text") | .text // ""')
                if test -n "$content"
                    echo "[$timestamp] 🤖 Claude: $content"
                end
                
                # Check for tool usage
                set tool_name (echo $line | jq -r '.message.content[]? | select(.type == "tool_use") | .name // ""')
                set tool_input (echo $line | jq -r '.message.content[]? | select(.type == "tool_use") | .input // ""')
                
                if test -n "$tool_name"
                    switch $tool_name
                        case "Write"
                            set file_path (echo $tool_input | jq -r '.file_path // ""')
                            set content_preview (echo $tool_input | jq -r '.content // ""' | head -c 100)
                            echo "[$timestamp] 📝 Writing file: $file_path"
                            if test -n "$content_preview"
                                echo "[$timestamp]    Content preview: $content_preview..."
                            end
                            
                        case "Edit"
                            set file_path (echo $tool_input | jq -r '.file_path // ""')
                            echo "[$timestamp] ✏️  Editing file: $file_path"
                            
                            # Try to show the diff if available
                            set old_str (echo $tool_input | jq -r '.old_str // ""')
                            set new_str (echo $tool_input | jq -r '.new_str // ""')
                            if test -n "$old_str"; and test -n "$new_str"
                                echo "[$timestamp] 📝 Changes:"
                                echo "[$timestamp]    - $old_str"
                                echo "[$timestamp]    + $new_str"
                            end
                            
                        case "Read"
                            set file_path (echo $tool_input | jq -r '.file_path // ""')
                            echo "[$timestamp] 📖 Reading file: $file_path"
                            
                        case "Bash"
                            set command (echo $tool_input | jq -r '.command // ""')
                            set description (echo $tool_input | jq -r '.description // ""')
                            if test -n "$description"
                                echo "[$timestamp] ⚡ Running: $description ($command)"
                            else
                                echo "[$timestamp] ⚡ Running: $command"
                            end
                            
                        case "Glob" "LS"
                            echo "[$timestamp] 🔍 Exploring files..."
                            set pattern (echo $tool_input | jq -r '.pattern // .path // ""')
                            if test -n "$pattern"
                                echo "[$timestamp]    Pattern: $pattern"
                            end
                            
                        case "TodoRead" "TodoWrite"
                            set todo_content (echo $tool_input | jq -r '.content // .todo // ""')
                            if test -n "$todo_content"
                                echo "[$timestamp] 📝 Todo: $todo_content"
                            else
                                echo "[$timestamp] 📝 Managing todos..."
                            end
                            
                        case "MultiEdit"
                            set file_path (echo $tool_input | jq -r '.file_path // ""')
                            echo "[$timestamp] ✏️  Multi-editing file: $file_path"
                            
                        case "Grep"
                            set pattern (echo $tool_input | jq -r '.pattern // ""')
                            set file_pattern (echo $tool_input | jq -r '.file_pattern // ""')
                            echo "[$timestamp] 🔍 Searching for '$pattern' in $file_pattern"
                            
                        case "Task"
                            set task_content (echo $tool_input | jq -r '.task // .content // ""')
                            echo "[$timestamp] 📋 Task: $task_content"
                            
                        case "WebSearch"
                            set query (echo $tool_input | jq -r '.query // ""')
                            echo "[$timestamp] 🌐 Web search: $query"
                            
                        case "WebFetch"
                            set url (echo $tool_input | jq -r '.url // ""')
                            echo "[$timestamp] �� Fetching: $url"
                            
                        case "NotebookRead" "NotebookEdit"
                            set notebook_path (echo $tool_input | jq -r '.notebook_path // .file_path // ""')
                            echo "[$timestamp] 📓 Notebook operation: $notebook_path"
                            
                        case '*'
                            echo "[$timestamp] 🔧 Using tool: $tool_name"
                    end
                end
                
            case "user"
                # Extract tool results - use the SIMPLE approach that works
                set tool_result (echo $line | jq -r '.message.content[]? | select(.type == "tool_result") | .content // ""')
                
                if test -n "$tool_result"
                    # Use the simple approach that works for file creation
                    echo "[$timestamp] 📄 Tool result:"
                    echo $line | jq -r '.message.content[]? | select(.type == "tool_result") | .content // ""'
                    echo "[$timestamp] ---"
                end
                
            case "result"
                set subtype (echo $line | jq -r '.subtype // ""')
                if test "$subtype" = "success"
                    set result (echo $line | jq -r '.result // ""')
                    set cost (echo $line | jq -r '.cost_usd // ""')
                    set duration (echo $line | jq -r '.duration_ms // ""')
                    
                    echo ""
                    echo "[$timestamp] ✅ Task completed!"
                    if test -n "$result"
                        echo "[$timestamp] 📄 Result: $result"
                    end
                    if test -n "$cost"; and test "$cost" != "null"; and test "$cost" != "0"
                        echo "[$timestamp] ⚠️  API Cost: \$$cost (You might be using API credits instead of Max subscription!)"
                        echo "[$timestamp] 💡 Run 'claude' then '/login' to switch to Max subscription"
                    else
                        echo "[$timestamp] ✅ Using Max subscription (no API charges)"
                    end
                    if test -n "$duration"
                        set duration_sec (math "$duration / 1000")
                        echo "[$timestamp] ⏱️  Duration: {$duration_sec}s"
                    end
                else
                    echo "[$timestamp] ❌ Task failed"
                end
                
            case '*'
                # Catch any other message types we might be missing
                echo "[$timestamp] 🐛 Unknown message type: $msg_type"
                echo "[$timestamp] 🐛 Raw: $line"
        end
    end
end
