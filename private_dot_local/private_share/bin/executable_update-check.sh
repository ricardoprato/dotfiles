#!/bin/bash
# Arch Linux Update Checker
# Checks for pacman and AUR updates

CACHE_FILE="/tmp/update-check-cache"
CACHE_AGE=3600  # 1 hora

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

check_updates() {
    local pacman_updates=0
    local aur_updates=0
    local pacman_list=""
    local aur_list=""

    # Verificar actualizaciones de pacman
    if command -v checkupdates &> /dev/null; then
        pacman_list=$(checkupdates 2>/dev/null)
        pacman_updates=$(echo "$pacman_list" | grep -c "^" 2>/dev/null || echo 0)
        [ -z "$pacman_list" ] && pacman_updates=0
    fi

    # Verificar actualizaciones de AUR (yay/paru)
    if command -v yay &> /dev/null; then
        aur_list=$(yay -Qua 2>/dev/null)
        aur_updates=$(echo "$aur_list" | grep -c "^" 2>/dev/null || echo 0)
        [ -z "$aur_list" ] && aur_updates=0
    elif command -v paru &> /dev/null; then
        aur_list=$(paru -Qua 2>/dev/null)
        aur_updates=$(echo "$aur_list" | grep -c "^" 2>/dev/null || echo 0)
        [ -z "$aur_list" ] && aur_updates=0
    fi

    echo "$pacman_updates $aur_updates"
    echo "$pacman_list" > /tmp/pacman-updates.txt
    echo "$aur_list" > /tmp/aur-updates.txt
}

show_updates() {
    read -r pacman_updates aur_updates <<< "$(check_updates)"
    local total=$((pacman_updates + aur_updates))

    echo ""
    echo -e "${BLUE}══════════════════════════════════════${NC}"
    echo -e "${BLUE}       Actualizaciones Disponibles    ${NC}"
    echo -e "${BLUE}══════════════════════════════════════${NC}"
    echo ""

    if [ "$total" -eq 0 ]; then
        echo -e "${GREEN}✓ Sistema actualizado${NC}"
        echo ""
        return 0
    fi

    if [ "$pacman_updates" -gt 0 ]; then
        echo -e "${YELLOW}󰮯 Pacman: ${pacman_updates} actualizaciones${NC}"
        echo -e "${BLUE}──────────────────────────────────────${NC}"
        cat /tmp/pacman-updates.txt | head -10
        [ "$pacman_updates" -gt 10 ] && echo "  ... y $((pacman_updates - 10)) más"
        echo ""
    fi

    if [ "$aur_updates" -gt 0 ]; then
        echo -e "${YELLOW}󰊠 AUR: ${aur_updates} actualizaciones${NC}"
        echo -e "${BLUE}──────────────────────────────────────${NC}"
        cat /tmp/aur-updates.txt | head -10
        [ "$aur_updates" -gt 10 ] && echo "  ... y $((aur_updates - 10)) más"
        echo ""
    fi

    echo -e "${BLUE}══════════════════════════════════════${NC}"
    echo -e "Total: ${RED}${total}${NC} actualizaciones"
    echo ""

    return "$total"
}

run_update() {
    echo -e "${YELLOW}Iniciando actualización...${NC}"
    echo ""
    
    if command -v yay &> /dev/null; then
        yay -Syu
    elif command -v paru &> /dev/null; then
        paru -Syu
    else
        sudo pacman -Syu
    fi
}

# Para waybar (solo número)
waybar_output() {
    read -r pacman_updates aur_updates <<< "$(check_updates)"
    local total=$((pacman_updates + aur_updates))
    
    if [ "$total" -gt 0 ]; then
        echo "{\"text\": \"󰮯 $total\", \"tooltip\": \"Pacman: $pacman_updates | AUR: $aur_updates\", \"class\": \"updates-available\"}"
    else
        echo "{\"text\": \"\", \"tooltip\": \"Sistema actualizado\", \"class\": \"updated\"}"
    fi
}

# Main
case "$1" in
    --waybar|-w)
        waybar_output
        ;;
    --update|-u)
        show_updates
        if [ $? -gt 0 ]; then
            echo -e "${YELLOW}¿Deseas actualizar ahora? [s/N]${NC} "
            read -r response
            if [[ "$response" =~ ^[SsYy]$ ]]; then
                run_update
            fi
        fi
        ;;
    --count|-c)
        read -r pacman_updates aur_updates <<< "$(check_updates)"
        echo $((pacman_updates + aur_updates))
        ;;
    *)
        show_updates
        if [ $? -gt 0 ]; then
            echo -e "${YELLOW}¿Deseas actualizar ahora? [s/N]${NC} "
            read -r response
            if [[ "$response" =~ ^[SsYy]$ ]]; then
                run_update
            fi
        fi
        ;;
esac
