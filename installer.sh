#!/bin/bash

#/dev/sda1 - /boot
#/dev/sda2 - / 
#/dev/sda3 - swap
#/dev/sda4 - /home

# Быстрые репы

> /etc/pacman.d/mirrorlist
cat <<EOF >>/etc/pacman.d/mirrorlist

##
## Arch Linux repository mirrorlist
## Generated on 2020-01-02
##

## Russia
#Server = http://mirror.rol.ru/archlinux/\$repo/os/\$arch
Server = https://mirror.rol.ru/archlinux/\$repo/os/\$arch
#Server = http://mirror.truenetwork.ru/archlinux/\$repo/os/\$arch
#Server = http://mirror.yandex.ru/archlinux/\$repo/os/\$arch
Server = https://mirror.yandex.ru/archlinux/\$repo/os/\$arch
#Server = http://archlinux.zepto.cloud/\$repo/os/\$arch

EOF

# Активируем новые репы
pacman-key --init
pacman-key --populate archlinux
pacman -Sy

# Форматируем в ext 4 наш диск
mkfs.ext4 /dev/sda1
# Монтируем диск к папке
mount /dev/sda1 /mnt

# Устанавливаем based и linux ядро + софт который нам нужен сразу и ставим amd-ucode либо intel-ucode что-то одно на ваш процессор
pacstrap /mnt base base-devel linux linux-firmware linux-headers netctl dhcpcd nano sudo grub dolphin konsole firefox dhcpcd networkmanager network-manager-applet intel-ucode  # parted

# прописываем fstab
genfstab -pU /mnt >> /mnt/etc/fstab

#Прокидываем правильные быстрые репы внутрь
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

# Делаем скрипт пост инстала:
cat <<EOF  >> /mnt/opt/install.sh

#!/bin/bash

echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen 
echo 'Обновим текущую локаль системы'
locale-gen

sleep 1

# Прописываем свой регион и город 
ln -sf /usr/share/zoneinfo/Asia/Irkutsk /etc/localtime
echo "/dev/sda /    ext4 defaults 0 1" > /etc/fstab
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
pacman-key --init
pacman-key --populate archlinux
pacman -Sy xorg nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader sddm 
pacman -Sy plasma 

nano /etc/hostname
mkinitcpio -p linux

#stemctl start dm
systemctl enable sddm NetworkManager
sleep 1
echo "password for root user:"
passwd
echo "add new user"
# Меняем 'lewis' на свой ник
useradd -m -g users -G wheel -s /bin/bash lewis
echo "paaswd for new user"
passwd lewis

nano /etc/sudoers
nano /etc/pacman.conf

exit

EOF

arch-chroot /mnt /bin/bash  /opt/install.sh
reboot
