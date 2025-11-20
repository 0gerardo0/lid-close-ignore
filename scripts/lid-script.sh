#!/bin/bash

set -e  

LOGIND_CONF="/etc/systemd/logind.conf"

detectar_estado() {
    echo "Detectando estado actual..."
    
    HANDLE_LID=$(grep "^HandleLidSwitch=" "$LOGIND_CONF" | cut -d= -f2)
    HANDLE_LID_DOCKED=$(grep "^HandleLidSwitchDocked=" "$LOGIND_CONF" | cut -d= -f2)
    LID_INHIBITED=$(grep "^LidSwitchIgnoreInhibited=" "$LOGIND_CONF" | cut -d= -f2)
    

    echo " Estado actual:"
    echo " - HandleLidSwitch: ${HANDLE_LID:-DEFAULT}"
    echo " - HandleLidSwitchDocked: ${HANDLE_LID_DOCKED:-DEFAULT}"
    echo " - LidSwitchIgnoreInhibited: ${LID_INHIBITED:-DEFAULT}"
}
modificar_conf() {
    local clave=$1
    local valor=$2
    local archivo=$3

    # Si la clave esta comentada, la descomenta y cambia el valor
    if grep -q "^#$clave=" "$archivo"; then
        sudo sed -i "s/^#$clave=.*/$clave=$valor/" "$archivo"
    # Si la clave existe, cambia su valor
    elif grep -q "^$clave=" "$archivo"; then
        sudo sed -i "s/^$clave=.*/$clave=$valor/" "$archivo"
    # Si no existe, la agrega al final
    else
        echo "$clave=$valor" | sudo tee -a "$archivo" >/dev/null
    fi
}

aplicar_cambios() {
    echo "IMPORTANTE: Para que los cambios surtan efecto, systemd-logind debe reiniciarse."
    echo "Esto cerrara tu sesion actual de usuario."
    read -rp "¿Quieres reiniciar logind ahora? (s/N): " confirmacion
    if [[ "$confirmacion" =~ ^[sS]$ ]]; then
        sudo systemctl restart systemd-logind
    else
        echo "Cambios guardados. Reinicia tu equipo manualmente para aplicar."
    fi
}

cambiar_configuracion() {
    local nuevo_estado=$1

    echo "Aplicando configuracion: '$nuevo_estado'..."

    if ! sudo -v; then
        echo "Error: Necesitas permisos de root."
        exit 1
    fi

    # Modifica el comportamiento principal de la tapa
    modificar_conf "HandleLidSwitch" "$nuevo_estado" "$LOGIND_CONF"
    modificar_conf "HandleLidSwitchDocked" "$nuevo_estado" "$LOGIND_CONF"

    # Configura si GNOME debe respetar o ignorar inhibidores externos
    if [[ "$nuevo_estado" == "ignore" ]]; then
        # Obliga a ignorar la tapa incluso si hay inhibidores activos
        modificar_conf "LidSwitchIgnoreInhibited" "no" "$LOGIND_CONF"
    else
        # Restaura el comportamiento por defecto
        modificar_conf "LidSwitchIgnoreInhibited" "yes" "$LOGIND_CONF"
    fi

    echo "Configuracion escrita correctamente."
    aplicar_cambios
}

mostrar_ayuda() {
    echo "Uso: lid-script [opcion]"
    echo "Opciones:"
    echo "  -s, --set <modo>   Modos: ignore, suspend, hibernate, poweroff"
    echo "  -h, --help         Muestra esta ayuda"
    exit 1
}

menu_interactivo() {
    detectar_estado
    echo "Selecciona una opcion:"
    echo " 1) Ignorar tapa (no suspender)"
    echo " 2) Suspender al cerrar"
    echo " 3) Hibernar al cerrar"
    echo " 4) Apagar al cerrar"
    echo " 5) Salir"

    read -rp ">> " opcion

    case $opcion in
        1) cambiar_configuracion "ignore" ;;
        2) cambiar_configuracion "suspend" ;;
        3) cambiar_configuracion "hibernate" ;;
        4) cambiar_configuracion "poweroff" ;;
        5) exit 0 ;;
        *) echo "Opcion no valida." ;;
    esac
}

if [[ $# -eq 0 ]]; then
    menu_interactivo
    exit 0
fi

case "$1" in
    -s|--set)
        if [[ -z "$2" || ! "$2" =~ ^(ignore|suspend|hibernate|poweroff)$ ]]; then
            echo "Error: Modo desconocido. Usa --help."
            exit 1
        fi
        cambiar_configuracion "$2"
        ;;
    -h|--help)
        mostrar_ayuda
        ;;
    *)
        mostrar_ayuda
        ;;
esac
