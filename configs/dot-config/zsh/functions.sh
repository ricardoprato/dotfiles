# Create a new directory and enter it
mkd() {
	mkdir -p "$@" && cd "$_";
}

fs() {
  if du -b /dev/null > /dev/null 2>&1; then
	  local arg=-sbh;
  else
	  local arg=-sh;
  fi
  if [[ -n "$@" ]]; then
	  du $arg -- "$@";
  else
	  du $arg .[^.]* ./*;
  fi;
}

# In case a command is not found, try to find the package that has it
function command_not_found_handler {
    local purple='\e[1;35m' bright='\e[0;1m' green='\e[1;32m' reset='\e[0m'
    printf 'zsh: command not found: %s\n' "$1"
    local entries=( ${(f)"$(/usr/bin/pacman -F --machinereadable -- "/usr/bin/$1")"} )
    if (( ${#entries[@]} )) ; then
        printf "${bright}$1${reset} may be found in the following packages:\n"
        local pkg
        for entry in "${entries[@]}" ; do
            local fields=( ${(0)entry} )
            if [[ "$pkg" != "${fields[2]}" ]] ; then
                printf "${purple}%s/${bright}%s ${green}%s${reset}\n" "${fields[1]}" "${fields[2]}" "${fields[3]}"
            fi
            printf '    /%s\n' "${fields[4]}"
            pkg="${fields[2]}"
        done
    fi
    return 127
}

# Detect the AUR wrapper
if pacman -Qi yay &>/dev/null ; then
   aurhelper="yay"
elif pacman -Qi paru &>/dev/null ; then
   aurhelper="paru"
fi

function in {
    local pkg="$1"
    if pacman -Si "$pkg" &>/dev/null ; then
        sudo pacman -S "$pkg"
    else 
        "$aurhelper" -S "$pkg"
    fi
}

function kt {
  local home_path="$HOME"
  local selected_dir=$(find "$home_path"/* -maxdepth 1 -mindepth 1 -type d |
    sed "s~$home_path/~~" |
    fzf --cycle --layout=reverse --prompt 't> ' |
    sed "s~^~$home_path/~")

  if [[ -n "$selected_dir" ]]; then
    local tab_name=$(basename "$selected_dir")
    kitty @ focus-tab --match title:"$tab_name" 2>/dev/null || kitty @ launch --type=tab --tab-title "$tab_name" --cwd "$selected_dir"
  fi
}

