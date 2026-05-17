function tdlm --description 'Tmux Dev Layout per subdir: tdlm <ai> [<ai2>]'
    if test (count $argv) -lt 1
        echo "Usage: tdlm <c|cx|codex|other_ai> [<second_ai>]"
        return 1
    end
    if test -z "$TMUX"
        echo "You must start tmux to use tdlm."
        return 1
    end

    set -l ai $argv[1]
    set -l ai2 $argv[2]
    set -l base (pwd)
    set -l first true

    tmux rename-session (basename "$base" | tr '.:' '--')

    for dir in $base/*/
        if test -d "$dir"
            set -l dirpath (string trim --right --chars=/ $dir)
            if test "$first" = "true"
                tmux send-keys -t "$TMUX_PANE" "cd '$dirpath' && tdl $ai $ai2" C-m
                set first false
            else
                set -l pane_id (tmux new-window -c "$dirpath" -P -F '#{pane_id}')
                tmux send-keys -t "$pane_id" "tdl $ai $ai2" C-m
            end
        end
    end
end
