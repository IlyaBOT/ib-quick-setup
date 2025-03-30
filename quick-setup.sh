#!/bin/bash
#Script made by IlyaBOT 13.02.2025

# TODO: Put the “git” installation check
#       into a separate function and call it.
# TODO: Make an item with GRUB configuration/customization.
# TODO: When installing the WhiteSur theme, install
#       also the theme for the Plank dock.

# Checking that the script is run with root permissions
#if [ "$EUID" -ne 0 ]; then
if [ "$(id -nu)" != "root" ]; then
#    echo "This script requires root privileges! Requesting password..."
    pass=$(whiptail --title "Authentication required"  --passwordbox "This script requires root privilege. Please, authenticate to begin the installation.\n\n[sudo] Password for user $USER:" 12 50 3>&2 2>&1 1>&3-)
    exec sudo -S "$0" "$@" <<< "$pass"
fi

# Checking "dialog" and "whiptail" installation
if ! command -v dialog &> /dev/null; then
    apt install -y dialog
fi
if ! command -v whiptail &> /dev/null; then
    apt install -y whiptail
fi

# Software list files
SOFTWARE_LIST="software_list.txt"
REMOVE_LIST="remove_list.txt"

# Check if there are files with the list of software, if not - create them
if [ ! -f "$SOFTWARE_LIST" ]; then
    cat <<EOL > "$SOFTWARE_LIST"
Accessories:htop neofetch mc ark gparted
Development:git vim gcc wine winetricks q4wine python3.11 python3.12 openjdk-17-jre openjdk-21-jre
Games:lutris minetest supertuxkart ioquake3 freedoom
Graphics:gimp inkscape krita kcolorchooser ghex
Internet:firefox chromium hexchat tigervnc-client filezilla links2
Multimedia:vlc mpv audacity ex-falso
Office:libreoffice libreoffice-writer libreoffice-calc libreoffice-math libreoffice-draw simple-scan
System:gnome-tweaks gnome-tweak-tool dosbox qemu-system-x86 qemu-system-arm qemu-system-ppc virt-manager cool-retro-term plank synaptic flatpak snapd
Other:cowsay lolcat beep
DesktopEnvironments:xfce4 lxde openbox kde-plasma-desktop gnome vanilla-gnome-desktop
EOL
fi

if [ ! -f "$REMOVE_LIST" ]; then
    cat <<EOL > "$REMOVE_LIST"
firefox
rhythmbox
cheese
gnome-mines
gnome-sudoku
EOL
fi

# Action selection menu
main_menu() {
    local choice
    choice=$(dialog --menu "    Select option:" 13 65 5 \
        1 "Install main packages" \
        2 "Uninstall standard and unused packages" \
        3 "Download WhiteSur theme and icons" \
        4 "Installing the Catppuccin Mocha theme for XFCE terminal" \
        5 "Additional settings (GRUB)" \
        6 "Exit" 2>&1 >/dev/tty)
    clear
    case $choice in
        1) category_menu ;;
        2) remove_unwanted ;;
        3) install_whitesur_theme ;;
        4) xfce-terminal_catttheme ;;
        5) extra_settings ;;
        6) exit 0 ;;
    esac
}

# Software category selection menu
category_menu() {
    local category
    category=$(dialog --menu "Select a software category:" 20 60 10 $(awk -F: '{print NR, $1}' "$SOFTWARE_LIST") 2>&1 >/dev/tty)
    clear

    if [ -n "$category" ]; then
        select_software "$category"
    fi
    main_menu
}

# Software selection in the category
select_software() {
    local category_index=$1
    local category_name=$(awk -F: 'NR=='"$category_index"'{print $1}' "$SOFTWARE_LIST")
    
    if [ -z "$category_name" ]; then
        dialog --msgbox "ERROR: Category not found!" 10 40
        return
    fi

    local packages=$(awk -F: -v cat="$category_name" '$1 == cat {print $2}' "$SOFTWARE_LIST")
    local options=()
    
    for pkg in $packages; do
        options+=("$pkg" "$pkg" "off")
    done

    if [ ${#options[@]} -eq 0 ]; then
        dialog --msgbox "ERROR: There is no software available in this category!" 10 40
        return
    fi

    local choices
    choices=$(dialog --separate-output --checklist "Select software for installation (Use the spacebar to select):" 20 60 15 "${options[@]}" 2>&1 >/dev/tty)
    clear

    if [ -n "$choices" ]; then
        install_selected $choices
    fi
}

# Software installation
install_selected() {
    echo -e "\nУстанавливаем выбранное ПО..."
    for pkg in $@; do
        echo "Установка: $pkg"
        apt install -y "$pkg"
        if [ "$pkg" == "beep" ]; then
            sed -i 's/^blacklist pcspkr/#blacklist pcspkr/' /etc/modprobe.d/blacklist.conf
            modprobe pcspkr
        fi
    done
    if echo "$@" | grep -E "xfce4"; then
        apt install -y "xfce4-goodies"
    fi
    if echo "$@" | grep -E "xfce4|lxde|openbox|kde-plasma-desktop|gnome|vanilla-gnome-desktop"; then
        dialog --msgbox "Installing multiple environments on the same system can cause problems. It is recommended to install only one desktop environment." 10 55
    fi
}

# Uninstalling default software
remove_unwanted() {
    dialog --yesno "Do you want to remove the default software and unnecessary packages?" 10 40
    response=$?
    clear
    if [[ "$response" -eq 0 ]]; then
        while read -r pkg; do
            if dpkg -l | grep -q " $pkg "; then
                echo "=== Uninstalling package: $pkg ==="
                apt remove -y "$pkg"
            fi
        done < "$REMOVE_LIST"
        apt autoremove -y
    fi
    main_menu
}

# Installing WhiteSur theme
install_whitesur_theme() {
    dialog --yesno "Do you want to install WhiteSur theme?" 10 40
    response=$?
    clear

    if [[ "$response" -eq 0 ]]; then	
		# Checking "git" installation

    	if ! command -v git &> /dev/null; then
    	    apt install -y git
    	fi

        git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git --depth=1
        cd WhiteSur-gtk-theme && ./install.sh && cd ..
    fi
    dialog --yesno "Do you want to install WhiteSur icons?" 10 40
    response=$?
    clear

    if [[ "$response" -eq 0 ]]; then
		# Checking "git" installation
    	if ! command -v git &> /dev/null; then
    	    apt install -y git
    	fi

        git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git --depth=1
        cd WhiteSur-icon-theme && ./install.sh && cd ..
    fi
    main_menu
}

# Additional Settings
extra_settings(){
	dialog --msgbox "Sorry, this section is not yet complete!" 10 30
    main_menu
}
#extra_settings() {
#    dialog --yesno "Do you want to customize GRUB?" 10 40
#    response=$?
#    clear
#    if [[ "$response" -eq 0 ]]; then
#        echo "Starting GRUB Customization..."
#        dialog --yesno "Do you want to change the GRUB bootloader background?" 10 50
#        dialog --yesno "Do you want to add “beep” as a power-on signal?" 10 50
#        # TODO: Add commands to change GRUB background and resolution, add beep-signals and more.
#        # TODO: Replace the multiple-question system with a list of available GRUB-Customization actions.
#    fi
#    
#    main_menu
#}

xfce-terminal_catttheme(){
    mkdir -p ~/.config/xfce4/terminal/
    mkdir -p ~/.local/share/xfce4/terminal/colorschemes/
    dialog --yesno "Do you want to install the Catppuccin Mocha theme for XFCE terminal?" 10 40
    response=$?
    clear
    if [[ "$response" -eq 0 ]]; then
        cat <<EOL > ~/.local/share/xfce4/terminal/colorschemes/Catppuccin-Mocha.theme
[Scheme]
Name=Catppuccin-Mocha
ColorCursor=#f5e0dc
ColorCursorForeground=#11111b
ColorCursorUseDefault=FALSE
ColorForeground=#cdd6f4
ColorBackground=#1e1e2e
ColorSelectionBackground=#585b70
ColorSelection=#cdd6f4
ColorSelectionUseDefault=FALSE
TabActivityColor=#fab387
ColorPalette=#45475a;#f38ba8;#a6e3a1;#f9e2af;#89b4fa;#f5c2e7;#94e2d5;#bac2de;#585b70;#f38ba8;#a6e3a1;#f9e2af;#89b4fa;#f5c2e7;#94e2d5;#a6adc8
EOL
        sed -i '/ColorCursor/d;/ColorCursorForeground/d;/ColorCursorUseDefault/d;/ColorForeground/d;/ColorBackground/d;/ColorSelectionBackground/d;/ColorSelection/d;/ColorSelectionUseDefault/d;/TabActivityColor/d;/ColorPalette/d' ~/.config/xfce4/terminal/terminalrc
        cat <<EOL >> ~/.config/xfce4/terminal/terminalrc
ColorCursor=#f5e0dc
ColorCursorForeground=#11111b
ColorCursorUseDefault=FALSE
ColorForeground=#cdd6f4
ColorBackground=#1e1e2e
ColorSelectionBackground=#585b70
ColorSelection=#cdd6f4
ColorSelectionUseDefault=FALSE
TabActivityColor=#fab387
ColorPalette=#45475a;#f38ba8;#a6e3a1;#f9e2af;#89b4fa;#f5c2e7;#94e2d5;#bac2de;#585b70;#f38ba8;#a6e3a1;#f9e2af;#89b4fa;#f5c2e7;#94e2d5;#a6adc8
EOL
    dialog --msgbox "The Catppuccin Mocha theme has been successfully installed for xfce4-terminal.\nIf it is not applied automatically, install it manually in the terminal settings and restart it." 10 50
    fi
    main_menu
}

# Starting the main menu
main_menu
