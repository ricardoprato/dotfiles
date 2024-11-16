function kt
    set home_path $HOME
    set selected_dir (find "$home_path"/* "$home_path"/.* -maxdepth 1 -mindepth 1 -type d | sed "s~$home_path/~~" | fzf --cycle --layout=reverse --prompt 't> ' | sed "s~^~$home_path/~")

    if test -n "$selected_dir"
        set tab_name (basename "$selected_dir")
        kitty @ focus-tab --match title:"^$tab_name" 2>/dev/null; or kitty @ launch --type=tab --tab-title "$tab_name" --cwd "$selected_dir"
    end
end

