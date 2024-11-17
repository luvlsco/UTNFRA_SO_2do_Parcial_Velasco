#!/bin/bash

# | Nombre del disco | Tamaño | Ruta     | Asunto              |
# |------------------|--------|----------|---------------------|
# | SSD_2GB          | 2 GiB  | /dev/sdb | Punto A (Parcial)   |
# | SSD_1GB          | 1 GiB  | /dev/sdc | Punto A (Parcial)   |
# | DEFENSA_PARCIAL  | 2 GiB  | /dev/sdd | Defensa del parcial |

# Variables para guardar las rutas de los discos SSD de 2GB y 1GB
SSD_2GB=$(sudo fdisk -l | grep "2 GiB" | awk '{print $2}' | awk -F ':' '{print $1}' | head -n 1)
SSD_1GB=$(sudo fdisk -l | grep "1 GiB" | awk '{print $2}' | awk -F ':' '{print $1}' | head -n 1)

# Creación de la partición del disco SSD de 2GB de tipo LVM
sudo fdisk $SSD_2GB << OEF
n
p
1


t
8e
w
OEF

# Creación de la partición del disco SSD de 1GB de tipo SWAP
sudo fdisk $SSD_1GB << OEF
n
p
1


t
82
w
OEF

# Variables para guardar las rutas de las particiones creadas (LVM/SWAP)
PARTICION_LVM=$(sudo fdisk -l | grep "Linux LVM" | awk '{print $1}')
PARTICION_SWAP=$(sudo fdisk -l | grep "Linux swap" | awk '{print $1}')

# Limpieza de ambas particiones
sudo wipefs -a $PARTICION_LVM $PARTICION_SWAP -ff

# Creación de volúmenes físicos en ambas particiones
sudo pvcreate $PARTICION_LVM $PARTICION_SWAP

# Creación de grupos de volúmenes en ambas particiones
sudo vgcreate vg_datos $PARTICION_LVM
sudo vgcreate vg_temp $PARTICION_SWAP

# Creación de los volúmenes lógicos dentro de los grupos de volúmenes creados
sudo lvcreate -L 5M -n lv_docker vg_datos
sudo lvcreate -L 1.5G -n lv_workareas vg_datos
sudo lvcreate -L 512M -n lv_swap vg_temp

# Variables para guardar las rutas de los volúmenes lógicos creados
LV_DOCKER=$(sudo fdisk -l | grep "lv_docker" | awk '{print $2}' | awk -F ':' '{print $1}')
LV_WORKAREAS=$(sudo fdisk -l | grep "lv_workareas" | awk '{print $2}' | awk -F ':' '{print $1}')
LV_SWAP=$(sudo fdisk -l | grep "lv_swap" | awk '{print $2}' | awk -F ':' '{print $1}')

# Formatear ambos volúmenes lógicos
sudo mkfs.ext4 $LV_DOCKER
sudo mkfs.ext4 $LV_WORKAREAS

# Configurar la partición SWAP y activarla
sudo mkswap $LV_SWAP
sudo swapon $LV_SWAP

# Creación de las carpetas donde se van a montar los volúmenes lógicos
sudo mkdir -p /work
sudo mkdir -p /var/lib/docker

# Montar los volúmenes lógicos en sus carpetas correspondientes
sudo mount $LV_DOCKER /var/lib/docker
sudo mount $LV_WORKAREAS /work

# Reiniciar docker después de montar los volúmenes lógicos
sudo systemctl restart docker
sudo systemctl start docker

# Montaje persistente
echo "$LV_DOCKER /var/lib/docker ext4 defaults 0 0" | sudo tee -a /etc/fstab
echo "$LV_WORKAREAS /work ext4 defaults 0 0" | sudo tee -a /etc/fstab
echo "$LV_SWAP none swap sw 0 0" | sudo tee -a /etc/fstab

sudo mount -a
