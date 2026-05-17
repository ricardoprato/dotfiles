function gd --description 'Remove current worktree + branch (confirm)'
    if gum confirm "Remove worktree and branch?"
        set -l cwd (pwd)
        set -l worktree (basename "$cwd")
        set -l root (string split -- '--' $worktree)[1]
        set -l branch (string split --max 1 -- '--' $worktree)[2]
        if test "$root" != "$worktree"
            cd "../$root"
            git worktree remove "$cwd" --force; or return 1
            git branch -D "$branch"
        end
    end
end
