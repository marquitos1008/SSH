#!/bin/bash

# Cargar funciones
source ../funciones/ssh_functions.sh

while true
do
    clear
    echo "===================================="
    echo "        GESTOR SSH - LINUX"
    echo "===================================="
    echo "1) Configurar SSH (Automático)"
    echo "2) Iniciar SSH"
    echo "3) Detener SSH"
    echo "4) Estado SSH"
    echo "5) Salir"
    echo "===================================="
    read -p "Seleccione una opción: " opcion

    case $opcion in
        1) configurar_ssh ;;
        2) iniciar_ssh ;;
        3) detener_ssh ;;
        4) estado_ssh ;;
        5) break ;;
        *) echo "Opción inválida"; sleep 2 ;;
    esac

    echo ""
    read -p "Presione ENTER para continuar..."
done