#!/bin/bash
set -uo pipefail

### Get infomation from user ###
hostname=$(dialog --stdout --inputbox "Enter hostname" 0 0) || exit 1
clear
: ${hostname:?"hostname cannot be empty"}

user=$(dialog --stdout --inputbox "Enter username" 0 0) || exit 1
clear
: ${user:?"user cannot be empty"}

password_user=$(dialog --stdout --passwordbox "Enter user password" 0 0) || exit 1
clear
: ${password_user:?"password cannot be empty"}
password_user2=$(dialog --stdout --passwordbox "Enter user password again" 0 0) || exit 1
clear
[[ "$password_user" == "$password_user2" ]] || ( echo "User passwords did not match"; exit 1; )

password_root=$(dialog --stdout --passwordbox "Enter root password" 0 0) || exit 1
clear
: ${password_root:?"password cannot be empty"}
password_root2=$(dialog --stdout --passwordbox "Enter root password again" 0 0) || exit 1
clear
[[ "$password_root" == "$password_root2" ]] || ( echo "Root password did not match"; exit 1; )

devicelist=$(lsblk -dplnx size -o name,size | grep -Ev "boot|rpmb|loop" | tac)
device=$(dialog --stdout --menu "Select installation disk" 0 0 0 ${devicelist}) || exit 1
clear

cardnets=$(ip link | grep -oh '.:\s\w*:' | tr -d ':') || exit 1
cardnet=$(dialog --stdout --menu "Select network card" 0 0 0 ${cardnets}) || exit 1
clear

myssid=$(dialog --stdout --inputbox "Enter ssid" 0 0) || exit 1
clear
: ${myssid:?"ssid cannot be empty"}

netpass=$(dialog --stdout --inputbox "Enter pass wifi" 0 0) || exit 1
clear
: ${netpass:?"wifi cannot be empty"}

exec 1> >(tee "stdout.log")
exec 2> >(tee "stderr.log")

wpa_supplicant -B -i ${cardnet} -c <(wpa_passphrase ID ${myssid} ${netpass})
dhcpcd ${cardnet}

loadkeys pl
setfont Lat2-Terminus16.psfu.gz -m 8859-2
timedatectl set-ntp true
gdisk ${device} x z y
pacstrap -i /mnt base base-devel
genfstab -U -p /mnt >> /mnt/etc/fstab
arch-chroot /mnt /bin/bash
ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
hwclock --systohc --utc
/etc/locale.gen
en_US.UTF-8 UTF-8
pl_PL.UTF-8 UTF-8
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "KEYMAP=pl
FONT=Lat2-Terminus16.psfu.gz
FONT_MAP=8859-2" >> /etc/vconsole.conf
echo "${hostname}" >> /etc/hostname
pacman -Sy iw wpa_supplicant dialog intel-ucode
mkinitcpio -p linux
echo ${password_root} | passwd --stdin
useradd -m -g user -G wheel,storage,power -s /bin/bash "$user"
echo ${password_user} | passwd $user --stdin
EDITOR=nano visudo # %wheel ALL=(ALL) ALL
pacman -Sy grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch --recheck
grub-mkconfig -o /boot/grub/grub.cfg
pacman -Sy gdm gnome-shell nautilus gnome-terminal gnome-tweak-tool gnome-control-center xdg-user-dirs networkmanager gnome-keyring network-manager-applet
systemctl enable gdm
systemctl enable NetworkManager
su - ${user} << ${password_user}
xdg-user-dirs-update
