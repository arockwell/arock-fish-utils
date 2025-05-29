function untracked
    begin
        for file in (git ls-files --others --exclude-standard)
            echo -e "\n\033[1;36m━━━ $file ━━━\033[0m"
            if string match -q "*.md" $file
                mdcat $file
            else
                bat $file
            end
            echo ""
        end
    end | less -R
end
