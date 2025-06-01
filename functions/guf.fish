# Defined interactively
function guf
    git status --porcelain | awk '{print $2}'
end
