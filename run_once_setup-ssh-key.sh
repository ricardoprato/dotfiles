#!/bin/bash
set -euo pipefail

SSH_DIR="$HOME/.ssh"
KEY="$SSH_DIR/id_ed25519"

# Ensure directory exists with correct permissions
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Generate ed25519 key if it doesn't exist
if [ ! -f "$KEY" ]; then
    echo "Generating SSH key ($KEY)..."
    ssh-keygen -t ed25519 -C "ricardoprato36@gmail.com" -f "$KEY" -N ""
    echo "SSH key generated. Add the public key to GitHub:"
    echo ""
    cat "$KEY.pub"
    echo ""
fi
