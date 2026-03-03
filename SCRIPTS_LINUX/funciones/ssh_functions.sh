#!/bin/bash

# ==========================================
# FUNCIONES SSH - GESTOR LINUX PROFESIONAL
# ==========================================

instalar_ssh() {
    if ! command -v sshd &> /dev/null; then
        echo "Instalando OpenSSH Server..."
        sudo dnf install -y openssh-server
    else
        echo "OpenSSH ya está instalado."
    fi
}

iniciar_ssh() {
    echo "Iniciando servicio SSH..."
    sudo systemctl enable sshd &>/dev/null
    sudo systemctl start sshd
    echo "Servicio SSH iniciado y habilitado."
}

detener_ssh() {
    echo "Deteniendo servicio SSH..."
    sudo systemctl stop sshd
    echo "Servicio SSH detenido."
}

estado_ssh() {
    echo "Estado actual del servicio SSH:"
    systemctl status sshd --no-pager
}

configurar_ssh() {

    clear
    echo "===================================="
    echo "CONFIGURANDO SSH (AUTO-DETECCIÓN PUENTE)"
    echo "===================================="

    instalar_ssh
    iniciar_ssh

    echo "Configurando firewall..."
    sudo firewall-cmd --permanent --add-service=ssh &>/dev/null
    sudo firewall-cmd --reload &>/dev/null

    # Detectar interfaz con gateway por defecto
    INTERFAZ=$(ip route | grep default | awk '{print $5}')

    # Obtener IP de esa interfaz
    IP_PUENTE=$(ip -4 addr show "$INTERFAZ" | grep inet | awk '{print $2}' | cut -d/ -f1)

    echo ""
    echo "===================================="
    echo "CONFIGURACIÓN COMPLETADA"
    echo "===================================="
    echo ""

    if [ -n "$IP_PUENTE" ]; then
        echo "Interfaz puente detectada: $INTERFAZ"
        echo "IP del servidor: $IP_PUENTE"
        echo ""
        echo "Desde tu máquina HOST ejecuta:"
        echo ""
        echo "ssh $USER@$IP_PUENTE"
        echo ""
        echo "Se te pedirá la contraseña del usuario."
    else
        echo "No se pudo detectar automáticamente la IP."
        echo "Ejecuta: ip a"
        echo "Y usa la IP del adaptador en modo puente."
    fi

    echo "===================================="
}