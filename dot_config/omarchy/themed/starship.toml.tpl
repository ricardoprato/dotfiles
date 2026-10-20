add_newline = true
command_timeout = 200
format = "[$directory$git_branch$git_status]($style)$character"

[character]
success_symbol = "[❯](bold {{ green }})"
error_symbol = "[✗](bold {{ red }})"

[directory]
truncation_length = 2
truncation_symbol = "…/"
style = "{{ accent }}"
repo_root_style = "bold {{ cyan }}"
read_only = " "
read_only_style = "bold {{ red }}"
repo_root_format = "[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style) "

[git_branch]
format = "[$branch]($style) "
style = "italic {{ magenta }}"

[git_status]
format     = '[$all_status]($style)'
style      = "{{ yellow }}"
ahead      = "⇡${count} "
diverged   = "⇕⇡${ahead_count}⇣${behind_count} "
behind     = "⇣${count} "
conflicted = "[ ](bold {{ red }})"
up_to_date = " "
untracked  = "[? ](bold {{ magenta }})"
modified   = "[ ](bold {{ yellow }})"
stashed    = ""
staged     = ""
renamed    = ""
deleted    = ""
