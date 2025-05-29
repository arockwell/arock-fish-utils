function killport
    if test (count $argv) -eq 0
        echo "Usage: killport <port_number>"
        return 1
    end
    
    set port $argv[1]
    set pids (lsof -ti :$port)
    
    if test (count $pids) -eq 0
        echo "No processes found running on port $port"
        return 0
    end
    
    echo "Killing processes on port $port: $pids"
    for pid in $pids
        kill -9 $pid
    end
    echo "Done!"
end
