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
    [Development]="git vim gcc make neovim code visual-studio-code-bin"
    [Browsers]="firefox brave-beta-bin google-chrome"
    [Multimedia]="vlc ffmpeg gimp"
    [Networking]="wget curl openssh discord"
    [Utilities]="zsh htop btop neofetch fastfetch tree gparted"
    [Desktops]="gnome plasma"
    [Liams_Picks]="firefox fastfetch nano neovim gnome tree btop zsh curl openssh vlc git discord gparted"
)

selected_packages=()
OPTIONS=("Select Packages" "Install Selected Packages" "Exit")
SELECTED=0

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
    echo "Pacman and yay utility. Will install yay automatically if needed (:"
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
    while true; do
        clear
        echo "Select a category (X to choose, Q to quit):"
        category_list=("${!categories[@]}")

        for i in "${!category_list[@]}"; do
            if [[ $i -eq $SELECTED ]]; then
                echo -e "\033[1;32m> ${category_list[$i]}\033[0m"
            else
                echo "  ${category_list[$i]}"
            fi
        done

        read -rsn1 key
        case $key in
            $ESC)
                read -rsn2 key
                case $key in
                    "[A") ((SELECTED--)) ;;
                    "[B") ((SELECTED++)) ;;
                esac
                ;;
            "q") return ;;
            "x")
                selected_category="${category_list[$SELECTED]}"
                packages=(${categories[$selected_category]})
                declare -A package_states
                
                for p in "${packages[@]}"; do
                    if [[ " ${selected_packages[@]} " =~ " $p " ]]; then
                        package_states["$p"]="on"
                    else
                        package_states["$p"]="off"
                    fi
                done

                count=0
                while true; do
                    clear
                    echo "Select packages from $selected_category (X to toggle, Q to confirm):"
                    for i in "${!packages[@]}"; do
                        if [[ $i -eq $count ]]; then
                            if [[ ${package_states["${packages[$i]}"]} == "on" ]]; then
                                echo -e "\033[1;32m> [x] ${packages[$i]}\033[0m"
                            else
                                echo -e "\033[1;32m> [ ] ${packages[$i]}\033[0m"
                            fi
                        else
                            if [[ ${package_states["${packages[$i]}"]} == "on" ]]; then
                                echo "  [x] ${packages[$i]}"
                            else
                                echo "  [ ] ${packages[$i]}"
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
                            package_states["${packages[$count]}"]=$( [[ ${package_states["${packages[$count]}"]} == "on" ]] && echo "off" || echo "on" )
                            ;;
                        "") break ;;
                        "q")
                            selected_packages=()
                            for p in "${packages[@]}"; do
                                if [[ ${package_states[$p]} == "on" ]]; then
                                    selected_packages+=("$p")
                                fi
                            done
                            break
                            ;;
                    esac
                    ((count < 0)) && count=0
                    ((count >= ${#packages[@]})) && count=$((${#packages[@]} - 1))
                done
                ;;
        esac
        ((SELECTED < 0)) && SELECTED=0
        ((SELECTED >= ${#category_list[@]})) && SELECTED=$((${#category_list[@]} - 1))
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
