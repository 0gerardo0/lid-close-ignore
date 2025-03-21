#!/bin/bash

set -e  

BIN_PATH="/usr/local/bin/lid-script"
LOGIND_CONF="/etc/systemd/logind.conf"
UPOWER_CONF="/etc/UPower/UPower.conf"
BACKUP_LOGIND="/etc/systemd/logind.conf.bak"
BACKUP_UPOWER="/etc/UPower/UPower.conf.bak"

# Función para restaurar configuraciones originales
restaurar_conf() {
    [[ -f "$BACKUP_LOGIND" ]] && sudo mv "$BACKUP_LOGIND" "$LOGIND_CONF"    
    [[ -f "$BACKUP_UPOWER" ]] && sudo mv "$BACKUP_UPOWER" "$UPOWER_CONF"
}

if [[ $EUID -eq 0 ]]; then
    echo "No ejecutes como root."
    exit 1
fi

sudo -v || { echo "No se obtuvo acceso root."; exit 1; }


case "$1" in
    --uninstall)
        echo "Desinstalando lid-script..."
        sudo rm -f "$BIN_PATH" && echo "Eliminado lid-script"

        read -rp "¿Deseas restaurar las configuraciones originales? (y/N): " option
        if [[ "$option" =~ ^[Yy]$ ]]; then
            restaurar_conf
        fi
        
        echo "Desinstalación completa."
        exit 0
        ;;
    
    -h|--help)
        echo -e "Uso: ./install.sh [opción]\n"
        echo "Opciones:"
        echo "  --help        Muestra esta ayuda."
        echo "  --uninstall   Desinstala lid-script y restaura configuraciones opcionales."
        exit 0
        ;;
esac

[[ -f "$LOGIND_CONF" && ! -f "$BACKUP_LOGIND" ]] && sudo cp "$LOGIND_CONF" "$BACKUP_LOGIND"
[[ -f "$UPOWER_CONF" && ! -f "$BACKUP_UPOWER" ]] && sudo cp "$UPOWER_CONF" "$BACKUP_UPOWER"

sudo install -m 755 scripts/lid-script.sh "$BIN_PATH"
echo "Instalación completa. Usa 'lid-script' o 'lid-script --set <option> para usar."
echo "Vease ./install --help"

