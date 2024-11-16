# fisher
set -g fisher_path $HOME/.local/share/fish/fisher
set fish_function_path $fish_function_path[1] $fisher_path/functions $fish_function_path[2..-1]
set fish_complete_path $fish_complete_path[1] $fisher_path/completions $fish_complete_path[2..-1]
for file in $fisher_path/conf.d/*.fish
  builtin source $file 2> /dev/null
end

if status is-interactive && ! functions --query fisher
  curl --silent --location https://git.io/fisher | source && fisher install jorgebucaran/fisher
end


if test -z "$NVIM"
  pokemon-colorscripts --no-title -r
end

# Initialize Starship and Zoxide
zoxide init fish | source
starship init fish | source

