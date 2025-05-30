# Defined in /Users/alexrockwell/.config/fish/config.fish @ line 34
function webhook_url --description 'Get the current webhook URL'
    if not set -q WEBHOOK_ENV
        set -g WEBHOOK_ENV "dev"  # Default to dev
    end
    
    for entry in $WEBHOOK_ENV_URLS
        set parts (string split ":" $entry -m 1)
        if test $parts[1] = $WEBHOOK_ENV
            echo $parts[2]
            return
        end
    end
    
    # Fallback to dev if environment not found
    echo "http://localhost:8000/webhooks/apify"
end
