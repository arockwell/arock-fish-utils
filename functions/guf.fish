# Defined interactively
function guf
    git diff --name-only  # modified tracked files
    git ls-files --others --exclude-standard  # untracked files
end
