#!/bin/bash

GIT_USER=''
GIT_MAIL=''
GIT_EDITOR='nvim'
GIT_BRANCH='main'

ANDROID_STUDIO_SHA_256="8919e8752979db73d8321e9babe2caedcc393750817c1a5f56c128ec442fb540"

AUR(){ # install AUR manager and aur software
    read -p "[?] Do you want to install YaY ?[Y/n]" yn ; [[ $yn == [yY] ]] || [[ $yn == "" ]] && \
        sudo pacman -S base-devel && (git clone https://aur.archlinux.org/yay /tmp/yay --depth 1&& cd /tmp/yay && makepkg -si) 2>&1
}

get_android_studio(){
    tools=$(mktemp)
    curl -L https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip -o $tools
    echo "$ANDROID_STUDIO_SHA_256 $tools" | sha256sum -c
    if [[ $? == 0 ]]; then
        mkdir -p $HOME/.local/Android/
        unzip $tools -d $HOME/.local/Android
        mkdir $HOME/.local/Android/cmdline-tools/latest/ && mv $HOME/.local/Android/cmdline-tools/{NOTICE.txt,bin,lib,source.properties} $HOME/.local/Android/cmdline-tools/latest/
        yes | sdkmanager --licenses
        sdkmanager --install "build-tools;34.0.0"
        sdkmanager --install "emulator"
        sdkmanager --install "platform-tools"
        sdkmanager --install "platforms;android-34"
        sdkmanager --install "system-images;android-34;google_apis_playstore;x86_64"
    else
        echo "Error while getting android studiO"
    fi
}

pacman_install(){ # generate pacman mirrorlist blackarch and install all software i need
    printf "[!] Reload pacman.conf\n"
    sudo rm -rf /etc/pacman.conf
    sudo cp src/pacman.conf /etc/pacman.conf
    printf "[!] Update package list\n"
    yay -Syy
    read -p "[?] Do you want to automaticaly regenerate pacman depots ? [Y/n]" yn
        [[ $(pacman -Qn reflector) == "" ]] && sudo pacman -S --noconfirm reflector &&
        [[ $yn == [Yy] ]] || [[ $yn == "" ]] && sudo reflector -c FR -c US -c GB -c PL -n 100 --info --protocol http,https --save /etc/pacman.d/mirrorlist
    read -p "[?] Do you want to add Blackarch repo ? [Y/n]" yn
        [[ $yn == [Yy] || $yn == '' ]] && (curl https://blackarch.org/strap.sh | sudo sh)
    read -p "[?] Do you want to install BlackArch software ? [Y/n]" yn
        [[ $yn == [Yy] || $yn == '' ]] && sudo pacman -S --noconfirm $(cat "src/black")
    read -p "[?] Do you want to install some games stations ? [y/n]" yn
        [[ $yn == [Yy] ]] && yay -S --noconfirm $(cat src/game)
    read -p "[?] Do you want to install some multimedia softare maker ? [y/n]" yn
        [[ $yn ==  [Yy] ]] && yay -S --noconfirm $(cat src/multi)
    read -p "[?] Do you want to install some dev tool and lang ? [y/n]" yn
        [[ $yn == [Yy] ]] && yay -S --noconfirm $(cat src/dev)
    read -p "[?] Do you want to install android studio ? [y/n]" yn
        [[ $yn == [Yy] ]] && get_android_studio
    sudo pacman -S --noconfirm $(cat "src/arch-base")
    yay -S --noconfirm $(cat "src/font")

}

setup_git(){ # generate .gitconfig
    if [[ ! -e $HOME/.gitconfig ]] ;then
        read -p "What is your username on GIT server : " GIT_USER && git config --global user.name $GIT_USER && printf "Your username is $GIT_USER\n"
        read -p "What is your email on GIT server : " GIT_MAIL && git config --global user.email $GIT_MAIL && printf "Your email is $GIT_MAIL\n"
        read -p "What is your editor for GIT commit and merge : " GIT_EDITOR && git config --global core.editor $GIT_EDITOR && printf "Your editor is $GIT_EDITOR\n"
        read -p "How do you want to name your default git branch :" && git config --global init.defaultBranch $GIT_BRANCH && printf "Your default branch is $GIT_BRANCH\n" *
        read -p "how do you want to rebase pull request [true/false]: " && git config --global pull.rebase $GIT_REBASE
    fi
}

install_DE(){ # setup DesktopEnvironement
    yay -S --noconfirm $(cat src/DE)
    cargo install xremap --features hypr
}

setup_system(){ # enable system dep
    sudo systemctl enable cups
    sudo systemctl enable bluetooth
    sudo systemctl enable ly
    sudo systemctl enable systemd-networkd
    sudo systemctl enable systemd-resolved
    sudo systemctl enable iwd
    sudo systemctl enable dhcpcd
    read -p "[?] What is the Name of your computer ?:" STATION && echo $STATION | sudo tee -a /etc/hostname
    printf '127.0.0.1\t\tlocalhost\n::1\t\t\tlocalhost\n127.0.1.1\t\t'$STATION | sudo tee -a /etc/hosts 2>/dev/null
    printf '# /TMP\ntmpfs\t\t\t/tmp\t\ttmpfs\t\trw,nodev,nosuid,size=7G\t\t\t0\t0\n' | sudo tee -a /etc/fstab
    sudo hwclock --systohc
    sudo ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
    sudo timedatectl set-ntp true
    sudo localectl set-keymap fr
        [[ $SHELL != "/bin/zsh" ]] && sudo chsh -s /bin/zsh
    (curl -fsSL https://raw.githubusercontent.com/platformio/platformio-core/master/scripts/99-platformio-udev.rules | sudo tee /etc/udev/rules.d/99-platformio-udev.rules)
}

rootless() {
    sudo chmod +s /sbin/shutdown
    sudo chmod +s /sbin/reboot
    [[ $SHELL != "/bin/zsh" ]] && chsh -s /bin/zsh
    systemctl --user enable podman.service
    echo "[registries.search]
registries = ['docker.io']
" | sudo tee -a /etc/containers/registries.conf
    echo "ip6_tables
ip6table_nat
ip_tables
iptable_nat
" | sudo tee -a /etc/modules-load.d/iptables.conf
    sudo cp src/sudoers /etc/sudoers
}

user_manager(){
    sudo usermod -aG input $USER
    sudo usermod -aG uucp $USER
    sudo usermod -aG wheel $USER
    sudo usermod -aG tty $USER
    sudo groupadd dialout
    sudo usermod -aG dialout $USER
}

install_package(){ ## install base software
    AUR
    pacman_install
}

config(){ ## setup
    setup_git
    install_DE
    dotfile
    setup_system
    user_manager
}

dotfile(){
    mkdir -p $HOME/.local/share/
    mkdir -p $HOME/.local/bin
    mkdir -p $HOME/.config
    if [[ ! -d $HOME/Wallpaper/ ]]; then
        git clone https://github.com/kawaegle/Wallpaper/ --depth 1 $HOME/Wallpaper
    fi
    if [[ ! -e $HOME/.local/bin/dotash ]]; then
        TMP=$(mktemp -d)
        git clone https://github.com/kawaegle/dotash --depth 1 "$TMP"
        (cd "$TMP" && pwd && ./install.sh)
    fi
    if [[ ! -d $HOME/.local/share/Dotfile ]]; then
        git clone https://github.com/kawaegle/dotfile/ --depth 1 "$HOME/.local/share/dotfile"
        (cd $HOME/.local/share/Dotfile && $HOME/.local/bin/dotash install)
    fi
    if [[ ! -d $HOME/Templates/ ]]; then
        git clone https://github.com/kawaegle/Templates $HOME/Templates --depth 1
    fi
}

finish(){
    printf "[!] Clean useless file\n"
    sudo pacman -Scc
    printf "[!] You 'll need to restart soon...\nBut no problem just wait we'll restart it for you.\n"; sleep 2
    printf "[!] Reboot in 5...\n"; sleep 1
    printf "[!] Reboot in 4...\n"; sleep 1
    printf "[!] Reboot in 3...\n"; sleep 1
    printf "[!] Reboot in 2...\n"; sleep 1
    printf "[!] Reboot in 1...\n"; sleep 1
    printf "[!] Reboot now..."
    sudo reboot
}

install_package
read -p "[?] Do you want to continue the configuration ? [Y/n] " yn
[[ $yn == [yY] ]] || [[ $yn == "" ]] && config
finish
