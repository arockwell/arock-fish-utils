function gp
    git push || git push --set-upstream origin "$(git branch --show-current)"
end
