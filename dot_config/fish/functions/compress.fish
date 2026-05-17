function compress --description 'tar+gzip a directory'
    set -l target (string trim --right --chars=/ $argv[1])
    tar -czf "$target.tar.gz" "$target"
end
