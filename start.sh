#!/bin/sh

GIT_USER=''
GIT_MAIL=''
GIT_PROTOCOL='https'
GIT_EDITOR='vim'
DE=''

PacConf()
{
  sudo rm -rf /etc/pacman.conf
  sudo cp src/pacman.conf /etc/pacman.conf
  sudo pacman -Scc
}

PacInstall()
{
  sudo pacman -Syy $(cat "src/PacInstall")
  printf "you have install all needed package form official server\n"
}

AUR()
{
  (  
  git clone https://aur.archlinux.org/trizen
  cd trizen
  makepkg -si
  cd ..
  rm -rf trizen
  )
}

AURInstall()
{
  trizen -S $(cat "src/AURInstall")
  printf "You have install all software from AUR repositories\n"
}

GIT()
{
  if [ -e $HOME/.gitconfig ]
  then
    mv $HOME/.gitconfig $HOME/.gitconfig.back
    read -p "What is your username on GIT server : " GIT_USER
    git config --global user.name $GIT_USER
    printf "Your username is $GIT_USER\n"
    read -p "What is your email on GIT server : " GIT_MAIL
    git config --global user.email $GIT_MAIL
    printf "Your email is $GIT_MAIL\n"
    read -p "What is your editor for GIT commit and merge : " GIT_EDITOR
    git config --global core.editor $GIT_EDITOR
    printf "Your editor is $GIT_EDITOR\n"
    read -p "What is your protocol (ssh/https) for GIT server : " GIT_PROTOCOL
    git config --global hub.protocol $GIT_PROTOCOL
    printf "Your protocol is $GIT_PROTOCOL\n"
  else
    read -p "What is your username on GIT server : " GIT_USER
    git config --global user.name $GIT_USER
    printf "Your username is $GIT_USER\n"
    read -p "What is your email on GIT server : " GIT_MAIL
    git config --global user.email $GIT_MAIL
    printf "Your email is $GIT_MAIL\n"
    read -p "What is your editor for GIT commit and merge : " GIT_EDITOR
    git config --global core.editor $GIT_EDITOR
    printf "Your editor is $GIT_EDITOR\n"
    read -p "What is your protocol (ssh/https) for GIT server : " GIT_PROTOCOL
    git config --global hub.protocol $GIT_PROTOCOL
    printf "Your protocol is $GIT_PROTOCOL\n"
  fi
}

DE()
{
  read -p "whitch Desktp Enviroment do you want\n\t[1]XFCE\n\t[2]I3WM" DE
  if [ $DE == 1 ]
  then 
    XFCE
  else
    I3
   fi
}

XFCE()
{
  trizen -S ${cat "src/xfce"}
  cp -r Dotfile/xfce $HOME/.config/xfce4
}

I3()
{
  trizen -S ${cat "src/i3"}
  cp -r Dotfile/i3 $HOME/.config/i3
}

conf()
{
   git clone https://github.com/alecromski/Dotfile
   git clone https://github.com/alecromski/Templates $HOME/
   git clone https://github.com/alecromski/Wallpaper $HOME/
}

firefox()
  {
    cp src/Firefox_ext.txt $HOME/
    git clone https://github.com/alecromski/start-pages $HOME/.local/
  }

Vim()
  {
    if [ -d $HOME/.vim ]
    then 
    printf "you have already a vim conf"
    else
    cp -r Dotfile/vim $HOME/.vim
    ln -sf $HOME/.vim/vimrc $HOME/.vimrc
    printf "You have now configurate vim\n"
    fi
  }

VSC()
  {
    mkdir -p $HOME/.config/VSCodium/User/	
    cp  Dotfile/VSsettings.json $HOME/.config/VSCodium/User/settings.json
    vscodium --install-extension jeff-hykin.better-shellscript-syntax
    sleep 2
    vscodium --install-extension coenraads.bracket-pair-colorizer
    sleep 2
    vscodium --install-extension naumovs.color-highlight
    sleep 2
    vscodium --install-extension platformio.platformio-ide
    sleep 2
    vscodium --install-extension shyykoserhiy.vscode-spotify
    sleep 2
    vscodium --install-extension daylerees.rainglow
    sleep 2
    vscodium --install-extension royaction.color-manager
    sleep 2
    vscodium --install-extension juanmnl.vscode-theme-1984
    printf "You have install and setup Vscodium"
  }

gesture()
{
    cp Dotfile/libinput-gestures.conf $HOME/.config/
    printf "you have config libinput gesture"
}

Zsh()
{
  cp Dotfile/zshrc $HOME/.zshrc
}

Config()
{
  conf
  gesture
  firefox
  Vim
  VSC
  Zsh
}

sysD()
{
  sudo systemctl enable lightdm
  sudo systemctl enable cronie
  sudo systemctl enable org.cups.cupsd
  libinput-gestures-setup autostart
  sudo usermod -aG input $USER
  sudo usermod -aG tty $USER
  sudo groupadd dialout
  sudo usermod -aG dialout $USER
}

SleepClear()
{
  sleep 5
  clear
}

main()
{
  PacConf
  PacInstall
  SleepClear
  AUR
  AURInstall
  SleepClear
  GIT
  SleepClear
  DE
  SleepClear
  Config
  SleepClear
  sysD
}

main
