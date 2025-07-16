set -x fish_user_paths
fish_add_path /bin
fish_add_path ~/.cargo/bin
fish_add_path ~/.local/bin
fish_add_path ~/.luarocks/bin
fish_add_path ~/Library/Python/3.{8,9}/bin
fish_add_path /usr/local/opt/sqlite/bin
fish_add_path /usr/local/sbin
fish_add_path ~/.gem/ruby/2.6.0/bin
fish_add_path ~/.local/share/pnpm
fish_add_path /bin/pnpm
fish_add_path ~/.local/share/bob-nvim/bin
fish_add_path /var/lib/flatpak/exports/bin/
fish_add_path ~/.dotnet/tools
set -gx DENO_INSTALL "~/.deno"
fish_add_path ~/.deno
