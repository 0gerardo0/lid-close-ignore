# Lid-Script: Configuración de cierre de tapa en Linux

Lid-Script gestiona el comportamiento del sistema al cerrar la tapa de una laptop. Está diseñado para entornos **GNOME** (X11 o Wayland) que utilizan **systemd-logind**.

Funciona en **Arch Linux** y cualquier distribución basada en systemd.

Su función principal es evitar la suspensión automática al cerrar la tapa, pero permite alternar fácilmente entre otros modos de energía.

## Requisitos

* Systemd (systemd-logind)
* Permisos de superusuario (sudo)
* Entorno de escritorio GNOME (recomendado para la gestión de inhibidores)

## Instalación

Ejecuta e instalar el script:

```bash
git clone https://github.com/0gerardo0/lid-close-ignore.git
cd lid-close-ignore
./install.sh
```

## Uso 
El script puede ejecutarse de forma interactiva o mediante argumentos.

### Modo interactivo
Simplemente ejecuta el comando sin argumentos para ver el menú:
```bash
lid-script
```

### CLI
Usa la bandera --set seguida del modo deseado:

```bash
# Ignorar el cierre de tapa (no suspender)
lid-script --set ignore

# Suspender al cerrar la tapa
lid-script --set suspend

# Hibernar al cerrar la tapa
lid-script --set hibernate

# Apagar al cerrar la tapa
lid-script --set poweroff
```
#### Notas técnicas
> [!NOTE]
> Al cambiar la configuración, el script modificará `/etc/systemd/logind.conf.`. Para aplicar los cambios, es necesario reiniciar el servicio `systemd-logind`, lo cual cerrará la sesión gráfica actual.

