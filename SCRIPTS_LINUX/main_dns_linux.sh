#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/funciones/dns_functions.sh"

while true; do
  clear
  echo "====== MENU DNS (AlmaLinux) ======"
  echo "1) Ver estado del servicio"
  echo "2) Instalar / Reinstalar DNS"
  echo "3) Configurar DNS base"
  echo "4) Agregar dominio"
  echo "5) Eliminar dominio"
  echo "6) Listar dominios (con IP)"
  echo "7) Monitorear servicio"
  echo "8) Volver al menú principal"
  read -p "Opción: " OP

  case $OP in
    1) estado_dns ;;
    2) instalar_dns ;;
    3) configurar_dns_base ;;
    4) agregar_dominio ;;
    5) eliminar_dominio ;;
    6) listar_dominios ;;
    7) monitorear_dns ;;
    8) return ;;
    *) echo "Opción inválida"; pause ;;
  esac
done