function format-drive --description 'Format drive as exFAT: format-drive <dev> <name>'
    if test (count $argv) -ne 2
        echo "Usage: format-drive <device> <name>"
        echo "Example: format-drive /dev/sda 'My Stuff'"
        echo
        echo "Available drives:"
        lsblk -d -o NAME -n | awk '{print "/dev/"$1}'
        return 1
    end
    set -l dev $argv[1]
    set -l name $argv[2]
    echo "WARNING: This will completely erase all data on $dev and label it '$name'."
    read -P "Are you sure? (y/N): " confirm
    if string match -qi 'y' -- $confirm
        sudo wipefs -a "$dev"
        sudo dd if=/dev/zero of="$dev" bs=1M count=100 status=progress
        sudo parted -s "$dev" mklabel gpt
        sudo parted -s "$dev" mkpart primary 1MiB 100%
        sudo parted -s "$dev" set 1 msftdata on
        set -l partition
        if string match -q '*nvme*' -- $dev
            set partition "$dev"p1
        else
            set partition "$dev"1
        end
        sudo partprobe "$dev"; true
        sudo udevadm settle; true
        sudo mkfs.exfat -n "$name" "$partition"
        echo "Drive $dev formatted as exFAT and labeled '$name'."
    end
end
