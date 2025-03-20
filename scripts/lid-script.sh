#!/bin/bash

set -e  # Si hay error, el script se detiene

# Archivos de configuración
LOGIND_CONF="/etc/systemd/logind.conf"
UPOWER_CONF="/etc/UPower/UPower.conf"

# Función para detectar el estado actual
detectar_estado() {
    echo "Detectando estado actual..."
    
    # Leer configuración actual de logind.conf
    HANDLE_LID=$(grep "^HandleLidSwitch=" "$LOGIND_CONF" | cut -d= -f2)
    HANDLE_LID_DOCKED=$(grep "^HandleLidSwitchDocked=" "$LOGIND_CONF" | cut -d= -f2)
    
    # Leer configuración actual de UPower.conf
    IGNORE_LID=$(grep "^IgnoreLid=" "$UPOWER_CONF" | cut -d= -f2)

    # Mostrar estado actual
    echo " Estado actual:"
    echo " - HandleLidSwitch: ${HANDLE_LID:-DEFAULT}"
    echo " - HandleLidSwitchDocked: ${HANDLE_LID_DOCKED:-DEFAULT}"
    echo " - IgnoreLid: ${IGNORE_LID:-DEFAULT}"
}

# Función para cambiar la configuración
cambiar_configuracion() {
    local nuevo_estado=$1

    echo "⚙️ Cambiando configuración a '$nuevo_estado'..."

    # Solicitar contraseña de sudo solo una vez
    if ! sudo -v; then
        echo "No tienes permisos de sudo o la contraseña es incorrecta."
        exit 1
    fi

    # Modificar logind.conf
    sudo sed -i "s/^HandleLidSwitch=.*/HandleLidSwitch=$nuevo_estado/" "$LOGIND_CONF" || echo "HandleLidSwitch=$nuevo_estado" | sudo tee -a "$LOGIND_CONF" >/dev/null
    sudo sed -i "s/^HandleLidSwitchDocked=.*/HandleLidSwitchDocked=$nuevo_estado/" "$LOGIND_CONF" || echo "HandleLidSwitchDocked=$nuevo_estado" | sudo tee -a "$LOGIND_CONF" >/dev/null

    # Modificar UPower.conf
    if [[ "$nuevo_estado" == "ignore" ]]; then
        sudo sed -i "s/^IgnoreLid=.*/IgnoreLid=true/" "$UPOWER_CONF" || echo "IgnoreLid=true" | sudo tee -a "$UPOWER_CONF" >/dev/null
    else
        sudo sed -i "s/^IgnoreLid=.*/IgnoreLid=false/" "$UPOWER_CONF" || echo "IgnoreLid=false" | sudo tee -a "$UPOWER_CONF" >/dev/null
    fi

    # Reiniciar servicios
    sudo systemctl restart systemd-logind
    sudo systemctl restart upower

    echo "Configuración aplicada correctamente."
}

# Función para menú interactivo
menu_interactivo() {
    echo "Selecciona una opción:"
    echo "1) Ignorar tapa (no suspender)"
    echo "2) Suspender al cerrar tapa"
    echo "3) Hibernar al cerrar tapa"
    echo "4) Apagar al cerrar tapa"
    echo "5) Salir"
    
    read -rp "Ingrese una opción: " opcion
    
    case $opcion in
        1) cambiar_configuracion "ignore" ;;
        2) cambiar_configuracion "suspend" ;;
        3) cambiar_configuracion "hibernate" ;;
        4) cambiar_configuracion "poweroff" ;;
        5) exit 0 ;;
        *) echo "Opción inválida." ;;
    esac
}

# Lógica principal
if [[ -z $1 ]]; then
    detectar_estado
    menu_interactivo
else
    cambiar_configuracion "$1"
fi

