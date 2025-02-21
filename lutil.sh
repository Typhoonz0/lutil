#!/bin/bash

ESC=$(printf "\033")

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root for pacman installations!"
    SUDO=sudo
else
    SUDO=""
fi

if ! command -v yay &>/dev/null; then
    echo "Yay not found. Installing yay..."
    $SUDO pacman -S --needed base-devel git
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd -
    rm -rf /tmp/yay
fi

declare -A categories
categories=(
    ["Other"]="discord gparted cmatrix"
    ["Development"]="git vim gcc make neovim code visual-studio-code-bin"
    ["Drivers"]="intel-ucode amd-ucode"
    ["Browsers"]="firefox brave-beta-bin google-chrome"
    ["Multimedia"]="vlc ffmpeg gimp libreoffice-still"
    ["Networking"]="wget curl openssh discord"
    ["Utilities"]="zsh btop neofetch fastfetch tree gparted"
    ["Desktops"]="gnome plasma"
)

selected_packages=()
OPTIONS=("Select Packages" "Install Selected Packages" "Exit")
SELECTED=0

LINES=$(tput lines)
PAGE_SIZE=$((LINES - 5))

task_install_packages() {
    echo "Installing packages..."
    for package in "${selected_packages[@]}"; do
        if pacman -Si "$package" &>/dev/null; then
            echo "Installing $package from pacman..."
            $SUDO pacman -S --noconfirm "$package"
        elif yay -Si "$package" &>/dev/null; then
            echo "Installing $package from yay..."
            yay -S --noconfirm "$package"
        else
            echo "Package $package not found in pacman or yay. Skipping."
        fi
    done
}

draw_menu() {
    clear
    echo "==== LUTIL ===="
    echo "Simple pacman and yay utility by liam"
    echo "X to select an option"
    echo "==============="
    for i in "${!OPTIONS[@]}"; do
        if [[ $i -eq $SELECTED ]]; then
            echo -e "\033[1;32m> ${OPTIONS[$i]}\033[0m"
        else
            echo "  ${OPTIONS[$i]}"
        fi
    done
}

select_packages() {
    declare -A package_states
    all_packages=()
    
    for category in "${!categories[@]}"; do
        for p in ${categories[$category]}; do
            all_packages+=("$p")
            package_states["$p"]="off"
        done
    done
    
    count=0
    while true; do
        clear
        echo "Select packages to install (X to toggle, Q to confirm):"
        echo "------------------------------------------------------"
        start=$((count > PAGE_SIZE ? count - PAGE_SIZE : 0))
        for ((i=start; i<count+PAGE_SIZE && i<${#all_packages[@]}; i++)); do
            p=${all_packages[$i]}
            if [[ $i -eq $count ]]; then
                if [[ ${package_states["$p"]} == "on" ]]; then
                    echo -e "\033[1;32m> [x] $p\033[0m"
                else
                    echo -e "\033[1;32m> [ ] $p\033[0m"
                fi
            else
                if [[ ${package_states["$p"]} == "on" ]]; then
                    echo "  [x] $p"
                else
                    echo "  [ ] $p"
                fi
            fi
        done
        
        read -rsn1 key
        case $key in
            $ESC)
                read -rsn2 key
                case $key in
                    "[A") ((count--)) ;;
                    "[B") ((count++)) ;;
                esac
                ;;
            "x")
                package_states["${all_packages[$count]}"]=$( [[ ${package_states["${all_packages[$count]}"]} == "on" ]] && echo "off" || echo "on" )
                ;;
            "q")
                selected_packages=()
                for p in "${all_packages[@]}"; do
                    if [[ ${package_states[$p]} == "on" ]]; then
                        selected_packages+=("$p")
                    fi
                done
                return
                ;;
        esac
        ((count < 0)) && count=0
        ((count >= ${#all_packages[@]})) && count=$((${#all_packages[@]} - 1))
    done
}

read_input() {
    read -rsn1 key
    case $key in
        $ESC)
            read -rsn2 key
            case $key in
                "[A") ((SELECTED--)) ;;
                "[B") ((SELECTED++)) ;;
            esac
            ;;
        "x")
            case $SELECTED in
                0) select_packages ;;
                1) task_install_packages ;;
                2) exit 0 ;;
            esac
            ;;
    esac
    ((SELECTED < 0)) && SELECTED=0
    ((SELECTED >= ${#OPTIONS[@]})) && SELECTED=$((${#OPTIONS[@]} - 1))
}

while true; do
    draw_menu
    read_input
done
