#!/bin/bash

if [[ $EUID -eq 0 ]]; then
    echo "No ejecutes como root."
    exit 1
fi

sudo -v || { echo "No se obtuvo acceso root."; exit 1; }

sudo install -m 755 lid-script.sh /usr/local/bin/lid-script
echo "✅ Instalación completa. Usa 'lid' para gestionar la tapa."

