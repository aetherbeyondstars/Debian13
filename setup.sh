#!/bin/bash

# ==================================================================================================
# ========================| Comprobamos si ejecutas el script como root. |==========================
# ==================================================================================================
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script debe ser ejecutado con privilegios de superusuario (sudo)"
    exit 1
fi
# ==================================================================================================



# ==================================================================================================
# =====================| Pedimos nombre de usuario para hacer las operaciones |=====================
# ==================================================================================================
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    default_user="$SUDO_USER"
else
    default_user=$(logname 2>/dev/null || who | awk '{print $1}' | head -n 1)
fi

if [ -n "$default_user" ]; then
    echo "¿Cual es el nombre del usuario que estas usando ahora mismo? [$default_user]"
    read -r input_usuario
    usuario="${input_usuario:-$default_user}"
else
    echo "¿Cual es el nombre del usuario que estas usando ahora mismo?"
    read -r usuario
fi

if ! id "$usuario" &>/dev/null; then
    echo "Error: El usuario '$usuario' no existe en el sistema."
    exit 1
fi
# ==================================================================================================



# ==================================================================================================
# ===================| Actualizamos los repositorios y actualizamos el sistema. |===================
# ==================================================================================================
clear
echo "Actualizando sistema y repositorios de Debian 13..."
sleep 2

apt update
apt upgrade -y
# ==================================================================================================



# ==================================================================================================
# ======================| Eliminamos los paquetes innecesarios del sistema. |=======================
# ==================================================================================================
bloat_packages=(
    gnome-sudoku gnome-tetravex gnome-taquin gnome-nibbles gnome-robots
    gnome-mines gnome-mahjongg gnome-klotski gnome-games gnome-chess
    gnome-2048 four-in-a-row five-or-more iagno hitori cheese quadrapassel
    swell-foop aisleriot tali lightsoff transmission-common transmission-gtk
    shotwell "libreoffice*" "debian-reference-*" gnome-sound-recorder evolution
    rhythmbox gnome-system-monitor "firefox*" "thunderbird*"
)

clear
echo "Desinstalando bloat del sistema..."
sleep 2

apt remove --purge "${bloat_packages[@]}" -y 2>/dev/null || true
# ==================================================================================================



# ==================================================================================================
# ======================| Limpiamos todo lo que haya podido quedar por ahí. |=======================
# ==================================================================================================
clear
echo "Eliminando archivos o paquetes residuales..."
sleep 2

apt autoremove --purge -y
# ==================================================================================================



# ==================================================================================================
# ===================| Función para verificar si un paquete está instalado. |=======================
# ==================================================================================================
is_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q '^ii'
}
# ==================================================================================================



# ==================================================================================================
# =================| Instalar Google Chrome en el caso de que no este instalado. |==================
# ==================================================================================================
clear
if ! is_installed "google-chrome-stable"; then
    echo "Descargando Google Chrome..."
    sleep 2
    apt install wget -y
    wget -O /tmp/googleChrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    
    clear
    echo "Instalando Google Chrome..."
    sleep 2
    apt install /tmp/googleChrome.deb -y
    rm -f /tmp/googleChrome.deb
else
    clear
    echo "Google Chrome ya está instalado, saltando este paso."
    sleep 2
fi
# ==================================================================================================



# ==================================================================================================
# ==========================| Instalación de otras aplicaciones útiles. |===========================
# ==================================================================================================
clear
echo "Instalando aplicaciones de interés y monitoreo..."
sleep 2

# Instalamos neofetch desde el proyecto local
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$script_dir/System/neofetch" ]; then
    echo "Instalando neofetch en /usr/local/bin/neofetch..."
    cp "$script_dir/System/neofetch" /usr/local/bin/neofetch
    chmod +x /usr/local/bin/neofetch
fi

# Añadimos neofetch a .bashrc del usuario si no está ya presente
if [ -f "/home/$usuario/.bashrc" ]; then
    if ! grep -qxF 'neofetch' "/home/$usuario/.bashrc"; then
        echo 'neofetch' >> "/home/$usuario/.bashrc"
    fi
fi

# Instalamos herramientas adicionales
apt install pciutils bpytop make -y
# ==================================================================================================



# ==================================================================================================
# ====================| Aquí se aplican los cambios estéticos a Debian 13 |=========================
# ==================================================================================================
clear
echo "Aplicando configuración estética en el sistema..."
sleep 1

# Aseguramos directorio dconf del usuario
mkdir -p "/home/$usuario/.config/dconf"
rm -f "/home/$usuario/.config/dconf/user"
cp "$script_dir/user" "/home/$usuario/.config/dconf/user"
chown -R "$usuario:$usuario" "/home/$usuario/.config"

echo "Aplicando nueva fuente en el sistema..."
sleep 1

mkdir -p /usr/share/fonts/truetype/productSans
cp "$script_dir/productSans.ttf" /usr/share/fonts/truetype/productSans/
fc-cache -f
# ==================================================================================================



# ==================================================================================================
# ==================================| Fondos de pantalla nuevos. |==================================
# ==================================================================================================
echo "Aplicando nuevo fondo de escritorio..."
sleep 1

# Debian 13 usa ceratopsian-theme y active-theme
for theme_dir in "/usr/share/desktop-base/ceratopsian-theme" "/usr/share/desktop-base/active-theme"; do
    if [ -d "$theme_dir/wallpaper" ]; then
        mkdir -p "$theme_dir/wallpaper/contents/images"
        cp "$script_dir"/Backgrounds/*.png "$theme_dir/wallpaper/contents/images/"
        cp "$script_dir/Backgrounds/gnome-background.xml" "$theme_dir/wallpaper/gnome-background.xml"
    fi
    if [ -d "$theme_dir/lockscreen" ]; then
        mkdir -p "$theme_dir/lockscreen/contents/images"
        cp "$script_dir"/Backgrounds/*.png "$theme_dir/lockscreen/contents/images/"
        cp "$script_dir/Backgrounds/gnome-background.xml" "$theme_dir/lockscreen/gnome-background.xml" 2>/dev/null || true
    fi
done
# ==================================================================================================



# ==================================================================================================
# ========================| Cambiamos el Plymouth de arranque del sistema. |========================
# ==================================================================================================
echo "Aplicando nuevo Plymouth de arranque del sistema..."
sleep 1

# Instalamos tema deb13 y deb10 para compatibilidad
mkdir -p /usr/share/plymouth/themes/deb13
cp "$script_dir"/Plymouth/* /usr/share/plymouth/themes/deb13/ 2>/dev/null || true

mkdir -p /usr/share/plymouth/themes/deb10
cp "$script_dir"/Plymouth/* /usr/share/plymouth/themes/deb10/ 2>/dev/null || true

cp "$script_dir/System/grub" /etc/default/grub

mkdir -p /etc/plymouth
cp "$script_dir/System/plymouthd.defaults" /etc/plymouth/plymouthd.conf
cp "$script_dir/System/plymouthd.defaults" /usr/share/plymouth/plymouthd.defaults

if command -v plymouth-set-default-theme &>/dev/null; then
    plymouth-set-default-theme deb13 2>/dev/null || plymouth-set-default-theme deb10 2>/dev/null || true
fi

update-initramfs -u
# ==================================================================================================



# ==================================================================================================
# ================================| Aplicamos la barra de tareas. |=================================
# ==================================================================================================
echo "Aplicando configuración de la barra de tareas compatible con GNOME 48..."
sleep 1

# Instalamos el paquete oficial de Debian 13 para GNOME 48
apt install gnome-shell-extension-dashtodock -y

# Copiamos la versión GNOME 48 al directorio del usuario para soporte local
mkdir -p "/home/$usuario/.local/share/gnome-shell/extensions/"
cp -r "$script_dir/Extensions/dash-to-dock@micxgx.gmail.com" "/home/$usuario/.local/share/gnome-shell/extensions/"
chown -R "$usuario:$usuario" "/home/$usuario/.local"
# ==================================================================================================



# ==================================================================================================
# ====================| Ponemos imágenes en negro durante el arranque de GRUB. |====================
# ==================================================================================================
echo "Aplicando imágenes en negro para GRUB..."
sleep 1

for grub_theme_dir in "/usr/share/desktop-base/ceratopsian-theme/grub" "/usr/share/desktop-base/active-theme/grub"; do
    if [ -d "$grub_theme_dir" ]; then
        cp "$script_dir"/System/Images/*.png "$grub_theme_dir/"
    fi
done

update-grub
# ==================================================================================================



# ==================================================================================================
# ==================| Eliminamos paquetes que se puedan haber instalado después. |==================
# ==================================================================================================
extra_packages=(
    "imagemagick*" "mozc*" "xiterm+thai" "mlterm*" "hdate*" "uim-gtk*" goldendict "anthy*"
)

clear
echo "Desinstalando posible bloat instalado posteriormente..."
sleep 2

apt remove --purge "${extra_packages[@]}" -y 2>/dev/null || true
# ==================================================================================================



# ==================================================================================================
# ==============| Una vez mas, limpiamos todo aquello que ha podido quedar por ahí. |===============
# ==================================================================================================
clear
echo "Eliminando archivos o paquetes residuales..."
sleep 2

apt autoremove --purge -y
# ==================================================================================================



# ==================================================================================================
# ==============================| Verificamos permisos del usuario |================================
# ==================================================================================================
chown -R "$usuario:$usuario" "/home/$usuario/.config" "/home/$usuario/.local" "/home/$usuario/.bashrc"
# ==================================================================================================



# ==================================================================================================
# =========| El script ha terminado su ejecución, el equipo se reiniciara en 5 segundos. |==========
# ==================================================================================================
clear
echo "Fin del script de personalización de Debian 13 (Trixie)!"
echo "¿Deseas reiniciar ahora para aplicar todos los cambios? [S/n]"
read -t 10 -r respuesta || respuesta="s"
if [[ "$respuesta" =~ ^[Nn]$ ]]; then
    echo "No se reiniciará el equipo. Recuerda reiniciar manualmente para aplicar todos los cambios."
else
    echo "Reiniciando el equipo en 5 segundos..."
    sleep 5
    reboot
fi
# ==================================================================================================
