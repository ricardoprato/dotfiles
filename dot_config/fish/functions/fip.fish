function fip --description 'SSH forward ports: fip <host> <port1> [port2] ...'
    if test (count $argv) -lt 2
        echo "Usage: fip <host> <port1> [port2] ..."
        return 1
    end
    set -l host $argv[1]
    for port in $argv[2..-1]
        ssh -f -N -L "$port:localhost:$port" $host
        and echo "Forwarding localhost:$port -> $host:$port"
    end
end
