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