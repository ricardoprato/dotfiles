function iso2sd --description 'Write ISO to SD card: iso2sd <iso> [device]'
    if test (count $argv) -lt 1
        echo "Usage: iso2sd <input_file> [output_device]"
        echo "Example: iso2sd ~/Downloads/ubuntu.iso /dev/sda"
        return 1
    end
    set -l iso $argv[1]
    set -l drive $argv[2]
    if test -z "$drive"
        set -l available (lsblk -dpno NAME | grep -E '/dev/sd')
        if test -z "$available"
            echo "No SD drives found and no drive specified"
            return 1
        end
        set drive (omarchy-drive-select "$available")
        if test -z "$drive"
            echo "No drive selected"
            return 1
        end
    end
    sudo dd bs=4M status=progress oflag=sync if="$iso" of="$drive"
    sudo eject "$drive"
end
