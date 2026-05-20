add_newline = true
command_timeout = 200
format = "[$directory$git_branch$git_status]($style)$character"

[character]
success_symbol = "[❯](bold {{ color2 }})"
error_symbol = "[✗](bold {{ color1 }})"

[directory]
truncation_length = 2
truncation_symbol = "…/"
style = "{{ accent }}"
repo_root_style = "bold {{ color6 }}"
read_only = " "
read_only_style = "bold {{ color1 }}"
repo_root_format = "[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style) "

[git_branch]
format = "[$branch]($style) "
style = "italic {{ color5 }}"

[git_status]
format     = '[$all_status]($style)'
style      = "{{ color3 }}"
ahead      = "⇡${count} "
diverged   = "⇕⇡${ahead_count}⇣${behind_count} "
behind     = "⇣${count} "
conflicted = "[ ](bold {{ color1 }})"
up_to_date = " "
untracked  = "[? ](bold {{ color5 }})"
modified   = "[ ](bold {{ color3 }})"
stashed    = ""
staged     = ""
renamed    = ""
deleted    = ""
