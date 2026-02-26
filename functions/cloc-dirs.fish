function cloc-dirs --description "🔥 cloc breakdown by top-level directory"
    set -l target (if test (count $argv) -gt 0; echo $argv[1]; else; echo .; end)
    set -l rows
    set -l max_code 0

    for dir in (fd --type d --max-depth 1 . $target | sort)
        set -l name (string replace -r "^$target/?" "" $dir)
        test -z "$name"; and continue
        set -l result (cloc --exclude-dir=__pycache__,.mypy_cache --quiet $dir 2>/dev/null | tail -2 | head -1)
        test -z "$result"; and continue
        set -l fields (string split -n " " (string replace -r '^\s*\S+\s+' '' $result))
        set -l files $fields[1]
        set -l blank $fields[2]
        set -l comment $fields[3]
        set -l code $fields[4]
        test -z "$code"; and continue
        set -a rows "$code|$files|$blank|$comment|$name"
        test $code -gt $max_code; and set max_code $code
    end

    test (count $rows) -eq 0; and echo "💀 Nothing found."; and return

    # Sort descending by code
    set rows (printf '%s\n' $rows | sort -t'|' -k1 -rn)

    # Header
    set_color --bold cyan
    printf "\n  ⚡ CODE BREAKDOWN: %s\n" (realpath $target)
    set_color normal
    printf "  %s\n\n" (string repeat -n 56 "─")
    set_color --bold
    printf "  %8s  %6s  %6s  %6s  %-20s  %s\n" "CODE" "FILES" "BLANK" "CMMNT" "BAR" "DIR"
    set_color normal
    printf "  %s\n" (string repeat -n 66 "─")

    set -l bar_max 20
    set -l icons 📦 🚀 🧪 📚 🔧 🎯 💎 🌟 🔥 ⚙️ 🎨 🛠️ 📡 🏗️ 🧩
    set -l idx 0

    for row in $rows
        set -l parts (string split "|" $row)
        set -l code $parts[1]
        set -l files $parts[2]
        set -l blank $parts[3]
        set -l comment $parts[4]
        set -l name $parts[5]

        set idx (math $idx + 1)
        set -l icon_idx (math "($idx - 1) % 15 + 1")
        set -l icon $icons[$icon_idx]

        # Bar — pad with spaces to fixed width
        set -l bar_len (math "round($code / $max_code * $bar_max)")
        test $bar_len -lt 1; and set bar_len 1
        set -l bar (string repeat -n $bar_len "█")
        set -l pad (string repeat -n (math "$bar_max - $bar_len") " ")

        set_color yellow
        printf "  %8s" $code
        set_color normal
        printf "  %6s  %6s  %6s  " $files $blank $comment
        set_color green
        printf "%s%s" $bar $pad
        set_color normal
        printf "  %s %s\n" $icon $name
    end

    # Total
    printf "  %s\n" (string repeat -n 66 "─")
    set -l total_code 0
    set -l total_files 0
    set -l total_blank 0
    set -l total_comment 0
    for row in $rows
        set -l parts (string split "|" $row)
        set total_code (math $total_code + $parts[1])
        set total_files (math $total_files + $parts[2])
        set total_blank (math $total_blank + $parts[3])
        set total_comment (math $total_comment + $parts[4])
    end
    set_color --bold magenta
    printf "  %8s  %6s  %6s  %6s  %-20s  🏆 TOTAL\n" $total_code $total_files $total_blank $total_comment ""
    set_color --bold yellow
    set -l grand (math $total_code + $total_blank + $total_comment)
    printf "  %8s  %6s  %6s  %6s  %-20s  📊 GRAND TOTAL\n\n" $grand "" "" "" ""
    set_color normal
end
