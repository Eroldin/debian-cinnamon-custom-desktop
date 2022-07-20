#!/bin/bash

set -e

: '
This script © 2022 by Erwin Oldebesten a.k.a. Eroldin is licensed under CC BY-SA 4.0
The human readable license: https://creativecommons.org/licenses/by-sa/4.0/
The actual license: https://creativecommons.org/licenses/by-sa/4.0/legalcode
'


#################################################################
#    This script is meant to be run on a cli Debian Bullseye    #
#          x86_64 & ARM64 system with only the "main"           #
#                 branch as it's repository.                    #
#################################################################


if [ "$EUID" = 0 ]; then
	echo "Do not run as root!"
	exit
fi

# This is against hash sum mismatch and broken packages, which can happen when using the "deb.debian.org" mirror.
# If something goes wrong while downloading the packages, just restart the script.
sudo rm -rf /var/lib/apt/lists/*
sudo apt clean

: '
This script checks which CPU is installed in your system. It also checks if you choose to install certain programs
and if you choose the "--no-install-recommends option".
Putting "i386-architecture" anywhere after "bash ./cinnamon-desktop.sh" will add said architecture to your system.
This is not necessary if you install wine with this script. 

No matter what, do NOT change the "INSTALL" variable. The error from ShellCheck has purposely been ignored. 
'

INSTALL=$@
CPUAAMD="$(lscpu | grep -o AuthenticAMD || true)"
CPUGI="$(lscpu | grep -o GenuineIntel || true)"
WINE="$(echo $INSTALL | grep -o wine || true)"
if [ "$WINE" = wine ]; then
	INSTALL=${INSTALL/wine/}
fi
I386A="$(echo $INSTALL | grep -o i386-architecture || true)"
FLATPAK="$(echo $INSTALL | grep -o flatpak || true)"
GS="$(echo $INSTALL | grep -o gnome-software || true)"
NIR="$(echo $INSTALL | grep -o \\--no-install-recommends || true)"

# This script determines if a specific browser has been chosen.
if [ "$(echo $INSTALL | grep -o firefox || true)" ]; then
	BROWSER="$BROWSER firefox"
	BROWSER_FLAT="$BROWSER_FLAT firefox"
fi
if [ "$(echo $INSTALL | grep -o chromium || true)" ]; then
	BROWSER="$BROWSER chromium"
	BROWSER_FLAT="$BROWSER_FLAT chromium"
fi
if [ "$(echo $INSTALL | grep -o midori || true)" ]; then
	BROWSER="$BROWSER midori"
	BROWSER_FLAT="$BROWSER_FLAT midori"
fi
if [ "$(echo $INSTALL | grep -o epiphany || true)" ]; then
	BROWSER="$BROWSER epiphany-browser"
	BROWSER_FLAT="$BROWSER_FLAT epiphany"
fi
if [ "$(echo $INSTALL | grep -o konqueror || true)" ]; then
	BROWSER="$BROWSER konqueror"
	BROWSER="$BROWSER konq-plugins"
fi
if [ "$(echo $INSTALL | grep -o chrome || true)" ]; then
	BROWSER_FLAT="$BROWSER_FLAT com.google.Chrome"
	if [ "$FLATPAK" != FLATPAK ]; then
		FLATPAK2=flatpak
	fi
	INSTALL=${INSTALL/chrome/}
fi
if [ "$(echo $INSTALL | grep -o brave || true)" ]; then
	BROWSER_FLAT="$BROWSER_FLAT brave"
	INSTALL=${INSTALL/brave/}
	if [ "$FLATPAK" != FLATPAK ]; then
		FLATPAK2=flatpak
	fi
fi
if [ "$(echo $INSTALL | grep -o librewolf || true)" ]; then
	BROWSER_FLAT="$BROWSER_FLAT librewolf"
	if [ "$FLATPAK" != FLATPAK ]; then
		FLATPAK2=flatpak
	fi
	INSTALL=${INSTALL/librewolf/}
fi
if [ "$(echo $INSTALL | grep -o vivaldi || true)" ]; then
	BROWSER="$BROWSER vivaldi-stable"
	INSTALL=${INSTALL/vivaldi/}
fi

# This script determines if a specific office suite has been chosen.
if [ "$(echo $INSTALL | grep -o libreoffice || true)" ]; then
	OFFICE="$OFFICE libreoffice"
	OFFICE_FLAT="$OFFICE_FLAT libreoffice"
fi
if [ "$(echo $INSTALL | grep -o abiword || true)" ]; then
	OFFICE="$OFFICE abiword"
	OFFICE_FLAT="$OFFICE_FLAT abiword"
fi
if [ "$(echo $INSTALL | grep -o gnumeric || true)" ]; then
	OFFICE="$OFFICE gnumeric"
	OFFICE_FLAT="$OFFICE_FLAT gnumeric"
fi
if [ "$(echo $INSTALL | grep -o onlyoffice || true)" ]; then
	OFFICE_FLAT="$OFFICE_FLAT onlyoffice"
	if [ "$FLATPAK" != FLATPAK ]; then
		FLATPAK2=flatpak
	fi
	INSTALL=${INSTALL/onlyoffice/}
fi

# This script determines if a specific mail client has been chosen.
if [ "$(echo $INSTALL | grep -o thunderbird || true)" ]; then
	MAILC="$MAILC thunderbird"
	MAILC_FLAT="$MALIC_FLAT thunderbird"
fi
if [ "$(echo $INSTALL | grep -o sylpheed || true)" ]; then
	MAILC="$MAILC sylpheed"
fi
if [ "$(echo $INSTALL | grep -o midori || true)" ]; then
	MAILC="$MAILC evolution"
	MAILC_FLAT="$MAILC_FLAT evolution"
fi

# This script determines if you choose to install VirtualBox.
if [ "$(echo $INSTALL | grep -o virtualbox || true)" ]; then
	VBOX=virtualbox-6.1
	INSTALL=${INSTALL/virtualbox/}
fi

# If flatpak is specified to be installed, these programs will NOT be installed with apt
if [ "$FLATPAK" = flatpak ]; then
	INSTALL=${INSTALL/firefox/}
	INSTALL=${INSTALL/chromium/}
	INSTALL=${INSTALL/midori/}
	INSTALL=${INSTALL/epiphany-browser/}
	INSTALL=${INSTALL/libreoffice/}
	INSTALL=${INSTALL/gnumeric/}
	INSTALL=${INSTALL/abiword/}
	INSTALL=${INSTALL/thunderbird/}
fi

# This script adds the multimedia, contrib and non-free repository to your system.
if [ ! -f /etc/apt/sources.list.d/deb-multimedia.list ]; then
	wget http://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2016.8.1_all.deb -O /tmp/keyring.deb
	sudo dpkg -i /tmp/keyring.deb
	sudo sed -i 's/main/main\ contrib\ non-free/g' /etc/apt/sources.list
	echo "deb http://deb-multimedia.org bullseye main non-free" | sudo tee /etc/apt/sources.list.d/deb-multimedia.list
	sudo apt update
fi

# Uncomment the commands below to install the latest kernel, depending on your CPU (amd64 for pc/laptop, arm64 for ARM devices).
: '
if [ "$CPUAAMD" = AuthenticAMD ]; then
	echo "deb http://deb.debian.org/debian bullseye-backports main contrib non-free" | sudo tee -a /etc/apt/sources.list.d/backports.list
	sudo apt update
	sudo apt install -t bullseye-backports -y linux-image-amd64
elif [ "$CPUGI" = GenuineIntel ]; then
	echo "deb http://deb.debian.org/debian bullseye-backports main contrib non-free" | sudo tee -a /etc/apt/sources.list.d/backports.list
	sudo apt update
	udo apt install -t bullseye-backports -y linux-image-amd64
else
	echo "deb http://deb.debian.org/debian bullseye-backports main contrib non-free" | sudo tee -a /etc/apt/sources.list.d/backports.list
	sudo apt update
	sudo apt install -t bullseye-backports -y linux-image-arm64
fi
'

: '
The microcode for your CPU gets installed on your system. It also add the 32-bit architecture repos
to your system in-case wine will be installed, or i386-architecture has been added.
This will not happen if you have an ARM64 processor
'
if [ "$CPUAAMD" = AuthenticAMD ]; then
	if [ "$I386A" = "i386-architecture" ]; then
		sudo dpkg --add-architecture i386
		sudo apt update
		INSTALL=${INSTALL/i386-architecture/}
	fi 
	if [ "$WINE" = wine ]; then
		if [ -z "${I386A+x}" ]; then
			sudo dpkg --add-architecture i386
			sudo apt update
		fi
	fi
	sudo apt update
	sudo apt install amd64-microcode -y
elif [ "$CPUGI" = GenuineIntel ]; then
	if [ "$I386A" = "i386-architecture" ]; then
		sudo dpkg --add-architecture i386
		sudo apt update
		INSTALL=${INSTALL/i386-architecture/}
	fi 
	if [ "$WINE" = wine ]; then
		if [ -z "${I386A+x}" ]; then
			sudo dpkg --add-architecture i386
			sudo apt update
		fi
	fi
	sudo apt install intel-microcode -y
else
	echo ""; echo "You are most likely on a non-Intel, non-AMD or ARM device. If not, install the microcode manually "
	sleep 3
fi

: '
This script installs (if there are any) updates, and installs a Cinnamon Desktop Environment aimed at offices, with commonly used software.
The "$@" at the beginning of the script,  makes sure you can give the names of extra packages you need, in the form of
"bash ./cinnamon-desktop.sh your_package1 your_package2 etc...", without the need to edit this script. If you do, make sure the packages
are written down correctly. You can also further minimalise this installation, by using the "--no-install-recommends" option.
For your convienience, if flatpak is installed, this script will automatically install the gnome-software flatpak plugin if you also choose to install gnome-software.
'


echo "vm.swappiness = 10" | sudo tee /etc/sysctl.d/99-swappiness.conf >/dev/null # We want vm.swappiness at this value, so that swap is only used if the system has 10% or lower available ram.

sudo apt dist-upgrade -y
sudo apt install -y cinnamon-core mate-themes cups cups-pdf hunspell pluma atril ristretto mpv vlc dconf-cli xdg-user-dirs-gtk system-config-printer fonts-liberation gnome-calculator unrar aspell-en aria2 $INSTALL "$NIR"
if [ "$GS" = gnome-software ]; then
	sudo apt install -y gdebi-core "$NIR"
else
	sudo apt install -y gdebi synaptic "$NIR"
fi
if [ "$WINE" = wine ]; then
	if [ $(dpkg-query -W -f='${Status}' wine 2>/dev/null | grep -c "ok installed" || true) -eq 0 ]; then
		if [ "$CPUAAMD" = AuthenticAMD ]; then
			sudo apt install -y wine wine32 wine64 libwine libwine:i386 fonts-wine mesa-vulkan-drivers libglx-mesa0:i386 mesa-vulkan-drivers:i386 libgl1-mesa-dri:i386 "$NIR"
		elif [ "$CPUGI" = GenuineIntel ]; then
			sudo apt install -y wine wine32 wine64 libwine libwine:i386 fonts-wine mesa-vulkan-drivers libglx-mesa0:i386 mesa-vulkan-drivers:i386 libgl1-mesa-dri:i386 "$NIR"
		fi
	fi
fi

# This makes sure that if some flatpaks are installed, while flatpak wasn't specified, there wont be a mixup between apt and flatpak
if [ "$FLATPAK" != flatpak ]; then
	if [ -z "${BROWSER+x}" ]; then
		if [ -z "${BROWSER_FLAT+x}" ]; then
			sudo apt install -y firefox-esr "$NIR"
		fi
	else
		if [ $(echo "$BROWSER" | grep -o vivaldi-stable || true) ]; then
			if [ ! -f /etc/apt/sources.list.d/vivaldi.list ]; then 
				aria2c -d /tmp https://repo.vivaldi.com/archive/linux_signing_key.pub
				sudo apt-key add /tmp/linux_signing_key.pub
				echo "deb https://repo.vivaldi.com/archive/deb/ stable main" | sudo tee /etc/apt/sources.list.d/vivaldi.list
				sudo apt update
			fi
			sudo apt install -y $BROWSER "$NIR"
		else
			sudo apt install -y  $BROWSER "$NIR"
			unset BROWSER_FLAT
		fi
	fi
	if [ -z "${OFFICE+x}" ]; then
		if [ -z "${OFFICE_FLAT+x}" ]; then
			sudo apt install -y libreoffice "$NIR"
		fi
	else
		sudo apt install -y $OFFICE "$NIR"
		unset OFFICE_FLAT
	fi
	if [ -z "${MAILC+x}" ]; then
		if [ ! $(echo "$MAILC" | grep -o sylpheed || true) ]; then
		        sudo apt install -y sylpheed "$NIR"
	        fi
	else
	
		sudo apt install -y $MAILC "$NIR"
		unset MAILC_FLAT
	fi
else
	if [ $(echo "$BROWSER" | grep -o vivaldi-stable || true) ]; then
		if [ ! -f /etc/apt/sources.list.d/vivaldi.list ]; then 
			aria2c -d /tmp https://repo.vivaldi.com/archive/linux_signing_key.pub
			sudo apt-key add /tmp/linux_signing_key.pub
			echo "deb https://repo.vivaldi.com/archive/deb/ stable main" | sudo tee /etc/apt/sources.list.d/vivaldi.list
			sudo apt update
		fi
		sudo apt install -y vivaldi-stable "$NIR"
	fi
fi

# If you choose to install virtualbox, this script will install the current (6.1) version of it.
if [ "$VBOX" = virtualbox-6.1 ]; then
	if [ $(dpkg-query -W -f='${Status}' virtualbox-6.1 2>/dev/null | grep -c "ok installed" || true) -eq 0 ]; then
		sudo apt install -y apt-transport-https
		if [ "$(uname -r | grep -o 5.18 || true )" != 5.18  ]; then
			if [ ! -f /etc/apt/sources.list.d/virtualbox.list ]; then
				aria2c -d /tmp https://www.virtualbox.org/download/oracle_vbox_2016.asc
				aria2c -d /tmp https://download.virtualbox.org/virtualbox/6.1.34/Oracle_VM_VirtualBox_Extension_Pack-6.1.34.vbox-extpack
				sudo gpg --dearmor --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg /tmp/oracle_vbox_2016.asc
				echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian bullseye contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list >/dev/null
				sudo apt update
			fi
			sudo apt install -y "$VBOX" "$NIR"
			echo "y" | sudo VBoxManage extpack install /tmp/Oracle_VM_VirtualBox_Extension_Pack-6.1.34.vbox-extpack
			sudo usermod "$USER" -aG vboxusers
			echo ""; echo 'You have been added to the "vboxusers" group.'
			sleep 3
		else
			echo ""; echo "Virtualbox currently does not run with the Linux 5.18 kernel,"; echo "so it won't be installed."
			sleep 3
		fi
	fi
fi

# If your system does not have an ARM64 processor, this script installs and configures Master PDF Editor 4. With it you can edit PDF files and fill in forms.
if [ $(dpkg-query -W -f='${Status}' master-pdf-editor 2>/dev/null | grep -c "ok installed" || true) -eq 0 ]; then
	if [ "$CPUAAMD" = AuthenticAMD ]; then
		aria2c -d /tmp http://code-industry.net/public/master-pdf-editor-4.3.89_qt5.amd64.deb
		sudo gdebi -n /tmp/master-pdf-editor-4.3.89_qt5.amd64.deb
		mkdir -p "$HOME/.config/Code Industry/"
		cat <<-EOF > "$HOME/.config/Code Industry/Master PDF Editor.conf"
			[General]
			app_style=Default
			check_updates=0
			close_app_normal=false
			last_check_update=1657893507
			main-version=4389
			parse_separate_all_forms=true
		EOF
		sudo mkdir -p /etc/skel/.config
		sudo cp -r "$HOME/.config/Code Industry" /etc/skel/.config
	elif [ "$CPUGI" = GenuineIntel ]; then
		aria2c -d /tmp http://code-industry.net/public/master-pdf-editor-4.3.89_qt5.amd64.deb
		sudo gdebi -z /tmp/master-pdf-editor-4.3.89_qt5.amd64.deb
		mkdir -p "$HOME/.config/Code Industry/"
		cat <<-EOF > "$HOME/.config/Code Industry/Master PDF Editor.conf"
			[General]
			app_style=Default
			check_updates=0
			close_app_normal=false
			last_check_update=1657893507
			main-version=4389
			parse_separate_all_forms=true
		EOF
		sudo mkdir -p /etc/skel/.config
		sudo cp -r "$HOME/.config/Code Industry" /etc/skel/.config
	fi
fi

# This script (if flatpak is installed), installs the flatpak plugin for Gnome Software (if installed).
# Uncomment the following lines down below, if you need the newer flatpak version for the Steam flatpak and the latest Proton versions.
: '
if [ ! -f /etc/apt/sources.list.d/backports.list ]; then
	echo "deb http://deb.debian.org/debian bullseye-backports main contrib non-free" | sudo tee -a /etc/apt/sources.list.d/backports.list
	sudo apt update
	sudo apt install -t buster-backports -y flatpak "$NIR"
else
	sudo apt install -t buster-backports -y flatpak "$NIR"
fi
'

if [ "$FLATPAK2" = flatpak ]; then
	if [ $(dpkg-query -W -f='${Status}' flatpak 2>/dev/null | grep -c "ok installed" || true) -eq 0 ]; then
		sudo apt install -y flatpak "$NIR"
	fi
fi
if [ $(dpkg-query -W -f='${Status}' flatpak 2>/dev/null | grep -c "ok installed" || true) -eq 1 ]; then
	sudo flatpak remote-add flathub https://flathub.org/repo/flathub.flatpakrepo || true
	sudo flatpak remotes > /dev/null || true
	if [ $(dpkg-query -W -f='${Status}' gnome-software 2>/dev/null | grep -c "ok installed" || true) -eq 1 ]; then
		sudo apt install -y gnome-software-plugin-flatpak "$NIR"
	fi
fi

# If flatpaks are designated to be installed. this script will do so.
if [ "$FLATPAK" = flatpak ]; then
	if [ -z "${BROWSER_FLAT+x}" ]; then
		if [ ! "$(echo $BROWSER | grep -o konqueror || true)" ]; then
			if [ ! "$(echo $BROWSER | grep -o vivaldi-stable || true)" ]; then
				sudo flatpak install -y --noninteractive com.google.Chrome || true
			fi
		fi
	else
		sudo flatpak install -y --noninteractive $BROWSER_FLAT || true
	fi
	if [ -z "${MAILC_FLAT+x}" ]; then
		if [ ! "$(echo $MAILC | grep -o sylpheed || true)" ]; then
			sudo flatpak install -y --noninteractive org.gnome.Evolution || true
		fi
	else
		sudo flatpak install -y --noninteractive $MAILC_FLAT || true
	fi
	if [ -z "${OFFICE_FLAT+x}" ]; then
		sudo flatpak install -y --noninteractive onlyoffice || true
	else
		sudo flatpak install -y --noninteractive $OFFICE_FLAT || true
	fi
fi
if [ "$FLATPAK2" = flatpak ]; then
	if [ -z "${BROWSER_FLAT+x}" ]; then
		sudo flatpak install -y --noninteractive $OFFICE_FLAT || true
	elif [ -z "${OFFICE_FLAT+x}" ]; then
		sudo flatpak install -y --noninteractive $BROWSER_FLAT || true
	else
		sudo flatpak install -y --noninteractive $BROWSER_FLAT $OFFICE_FLAT || true
	fi
fi

# This script makes certain your system boots into a graphical environment and makes it ready for the use of Network Manager.
sudo systemctl set-default graphical.target
cat <<-EOF | sudo tee /etc/network/interfaces > /dev/null
	# This file describes the network interfaces available on your system
	# and how to activate the. For more information, see interfaces(5).

	source /etc/network/interfaces.d/*

	# The loopback network interface
	auto lo
	iface lo inet loopback
EOF

# This script configures the default applications for your system.
cat <<-EOF > "$HOME/.config/mimeapps.list"
	[Default Applications]
	application/pdf=atril.desktop
	image/bmp=ristretto.desktop
	image/gif=ristretto.desktop
	image/jpeg=ristretto.desktop
	image/png=ristretto.desktop
	image/svg+xml=ristretto.desktop
	image/tiff=ristretto.desktop
	image/x-pixmap=ristretto.desktop
	image/x-xpixmap=ristretto.desktop

	[Added Associations]
	application/pdf=atril.desktop;
	image/bmp=ristretto.desktop;
	image/gif=ristretto.desktop;
	image/jpeg=ristretto.desktop;
	image/png=ristretto.desktop;
	image/svg+xml=ristretto.desktop;
	image/tiff=ristretto.desktop;
	image/x-pixmap=ristretto.desktop;
	image/x-xpixmap=ristretto.desktop;
EOF
sudo cp "$HOME/.config/mimeapps.list" /etc/skel/.config/mimeapps.list


# A notifcation of the upcomming reboot is given. This script reboots the system in 3 seconds.
clear; echo "A custom Cinnamon Desktop Environment has been installed,"
echo "your system will reboot..."
sleep 3

sudo reboot
