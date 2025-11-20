#!/bin/bash

set -e  

BIN_PATH="/usr/local/bin/lid-script"
LOGIND_CONF="/etc/systemd/logind.conf"
BACKUP_LOGIND="/etc/systemd/logind.conf.bak"

# Función para restaurar configuraciones originales
restaurar_conf() {
    if [[ -f "$BACKUP_LOGIND" ]]; then
        sudo mv "$BACKUP_LOGIND" "$LOGIND_CONF"
        echo "Configuración de logind restaurada."
    else
        echo "No se encontró copia de seguridad de logind."
    fi
}

if [[ $EUID -eq 0 ]]; then
    echo "No ejecutes como root."
    exit 1
fi

sudo -v || { echo "No se obtuvo acceso root."; exit 1; }


case "$1" in
    --uninstall)
        echo "Desinstalando lid-script..."
        sudo rm -f "$BIN_PATH" && echo "Script eliminado de $BIN_PATH"

        read -rp "¿Deseas restaurar la configuración original de logind? (y/N): " option
        if [[ "$option" =~ ^[Yy]$ ]]; then
            restaurar_conf
            # Reiniciar logind tras restaurar es buena práctica
            echo "NOTA: Deberías reiniciar tu sesión o ejecutar 'sudo systemctl restart systemd-logind' para aplicar la restauración."
        fi
        
        echo "Desinstalación completa."
        exit 0
        ;;
    
    -h|--help)
        echo "Uso: ./install.sh [opción]"
        echo "Opciones:"
        echo "  --help        Muestra esta ayuda."
        echo "  --uninstall   Desinstala lid-script y ofrece restaurar backup."
        exit 0
        ;;
esac

# Crear backup solo si no existe uno previo para no sobrescribir el original real
if [[ -f "$LOGIND_CONF" && ! -f "$BACKUP_LOGIND" ]]; then
    echo "Creando copia de seguridad de $LOGIND_CONF..."
    sudo cp "$LOGIND_CONF" "$BACKUP_LOGIND"
fi

echo "Instalando script..."
sudo install -m 755 scripts/lid-script.sh "$BIN_PATH"

echo "Instalación completa."
echo "Ejecuta 'lid-script' para iniciar el menú interactivo."
