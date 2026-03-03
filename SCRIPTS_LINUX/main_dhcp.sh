#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/funciones/dhcp_functions.sh"

while true; do
  clear
  echo "====== MENU DHCP (AlmaLinux) ======"
  echo "1) Ver estado del servicio"
  echo "2) Instalar / Reinstalar DHCP"
  echo "3) Configurar DHCP"
  echo "4) Monitorear concesiones"
  echo "5) Volver al menú principal"
  read -p "Opción: " OP

  case $OP in
    1) estado_dhcp ;;
    2) instalar_dhcp ;;
    3) configurar_dhcp ;;
    4) monitorear_dhcp ;;
    5) return ;;
    *) echo "Opción inválida"; pause ;;
  esac
done