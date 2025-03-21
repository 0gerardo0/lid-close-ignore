#!/bin/bash

set -e  

LOGIND_CONF="/etc/systemd/logind.conf"
UPOWER_CONF="/etc/UPower/UPower.conf"

detectar_estado() {
    echo "Detectando estado actual..."
    
    HANDLE_LID=$(grep "^HandleLidSwitch=" "$LOGIND_CONF" | cut -d= -f2)
    HANDLE_LID_DOCKED=$(grep "^HandleLidSwitchDocked=" "$LOGIND_CONF" | cut -d= -f2)
    
    IGNORE_LID=$(grep "^IgnoreLid=" "$UPOWER_CONF" | cut -d= -f2)

    echo " Estado actual:"
    echo " - HandleLidSwitch: ${HANDLE_LID:-DEFAULT}"
    echo " - HandleLidSwitchDocked: ${HANDLE_LID_DOCKED:-DEFAULT}"
    echo " - IgnoreLid: ${IGNORE_LID:-DEFAULT}"
}

modificar_conf() {
    local clave=$1
    local valor=$2
    local archivo=$3

    if grep -q "^#$clave=" "$archivo"; then
        sudo sed -i "s/^#$clave=.*/$clave=$valor/" "$archivo"
    elif grep -q "^$clave=" "$archivo"; then
        sudo sed -i "s/^$clave=.*/$clave=$valor/" "$archivo"
    else
        echo "$clave=$valor" | sudo tee -a "$archivo" >/dev/null
    fi
}

cambiar_configuracion() {
    local nuevo_estado=$1

    echo "Cambiando configuración a '$nuevo_estado'..."

    if ! sudo -v; then
        echo "No tienes permisos de sudo o la contraseña es incorrecta."
        exit 1
    fi

    modificar_conf "HandleLidSwitch" "$nuevo_estado" "$LOGIND_CONF"
    modificar_conf "HandleLidSwitchDocked" "$nuevo_estado" "$LOGIND_CONF"
    
    if [[ "$nuevo_estado" == "ignore" ]]; then
        modificar_conf "IgnoreLid" "true" "$UPOWER_CONF"
    else
        modificar_conf "IgnoreLid" "false" "$UPOWER_CONF"
    fi
    
    sudo systemctl restart upower
    echo "Configuración aplicada correctamente."
}

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

if [[ -z $1 ]]; then
    detectar_estado
    menu_interactivo
else
    cambiar_configuracion "$1"
fi

