#!/bin/bash

set -e

if [[ $EUID -ne 0 ]]; then
    echo "⚠️ Debe ejecutarse como root."
    exit 1
fi

INSTALL_PATH="/usr/local/bin/lid-toggle"

echo "📦 Instalando script en $INSTALL_PATH..."
cp scripts/lid-toggle.sh "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"

echo "✅ Instalación completada. Ahora puedes ejecutar:"
echo "    sudo lid-toggle"

