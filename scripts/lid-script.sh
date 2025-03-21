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

mostrar_ayuda() {
    echo -e "\n╭────────────────────────────────────────────────────────────────╮"
    echo -e "│                       Uso: lid-script [opción]                  │"
    echo -e "╰────────────────────────────────────────────────────────────────╯\n"
    
    echo -e "Opciones disponibles:\n"
    echo -e "  -s, --set <modo>   Cambiar el modo de gestión de la tapa"
    echo -e "  -h, --help         Mostrar esta ayuda\n"
    
    echo -e "Modos disponibles:\n"
    echo -e "  ignore     → No suspender al cerrar la tapa"
    echo -e "  suspend    → Suspender al cerrar la tapa"
    echo -e "  hibernate  → Hibernar al cerrar la tapa"
    echo -e "  poweroff   → Apagar al cerrar la tapa\n"

    echo -e "╭────────────────────────────────────────────────────────────────╮"
    echo -e "│                Ejemplo de uso: lid-script -s suspend           │"
    echo -e "╰────────────────────────────────────────────────────────────────╯\n"
    exit 1
}

menu_interactivo() {
    detectar_estado
    echo -e "\n\033[1;34m╭──────────────────────────────────────╮\033[0m"
    echo -e " \033[1;34m│         Configuración de tapa         │\033[0m"
    echo -e "\033[1;34m╰──────────────────────────────────────╯\033[0m"

    echo -e "\033[1;32m 1) Ignorar tapa (no suspender)\033[0m"
    echo -e "\033[1;32m 2) Suspender al cerrar tapa\033[0m"
    echo -e "\033[1;32m 3) Hibernar al cerrar tapa\033[0m"
    echo -e "\033[1;32m 4) Apagar al cerrar tapa\033[0m"
    echo -e "\033[1;31m 5) Salir\033[0m"

    echo -e "\n\033[1;33mSeleccione una opción:\033[0m"
    read -rp ">> " opcion

    case $opcion in
        1) cambiar_configuracion "ignore" ;;
        2) cambiar_configuracion "suspend" ;;
        3) cambiar_configuracion "hibernate" ;;
        4) cambiar_configuracion "poweroff" ;;
        5) exit 0 ;;
        *) echo -e "\033[1;31mOpción inválida.\033[0m" ;;
    esac
}

if [[ $# -eq 0 ]]; then
    menu_interactivo
    exit 0
fi

case "$1" in
    -s|--set)
        if [[ -z "$2" || ! "$2" =~ ^(ignore|suspend|hibernate|poweroff)$ ]]; then
            echo "Error: Debes especificar un modo válido. Usa --help para más información."
            mostrar_ayuda
            exit 1
        fi
        cambiar_configuracion "$2"
        ;;
    -h|--help)
        mostrar_ayuda
        ;;
    *)
        echo "Error: Opción desconocida '$1'. Usa --help para más información."
        mostrar_ayuda
        exit 1
        ;;
esac
