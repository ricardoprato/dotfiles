function tm --description 'pick a sesh session with fzf and connect (works inside and outside tmux)'
    # Outside tmux sesh attaches; inside tmux it switches the client. tmux's
    # Alt+d popup runs this same function, so the picker lives in one place.
    # dir-candidates appends a filesystem walk so dirs never visited still show up.
    set -l selected (begin; sesh list --icons; dir-candidates; end | awk 'NF && !seen[$0]++' | fzf --ansi --no-preview --reverse --prompt 'dir > ' --scheme=history --tiebreak=index)
    test -n "$selected"; or return 0
    sesh connect $selected
end
