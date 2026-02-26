#!/bin/bash

VERSION="2.0"
INTERFAZ="enp0s8"

# ==========================
# VALIDACIONES GENERALES
# ==========================

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Debe ejecutarse como root."
        exit 1
    fi
}

check_dependencies() {
    command -v ip &> /dev/null || dnf install -y iproute &> /dev/null
    command -v ping &> /dev/null || dnf install -y iputils &> /dev/null
}

ip_valida() {
    local ip=$1
    [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
    for i in $(echo $ip | tr "." " "); do
        [ $i -ge 0 ] 2>/dev/null && [ $i -le 255 ] || return 1
    done

    case $ip in
        0.0.0.0|127.0.0.0|127.0.0.1|255.255.255.255) return 1 ;;
    esac

    return 0
}

ip_a_num() {
    IFS=. read -r i1 i2 i3 i4 <<< "$1"
    echo $(( (i1<<24) + (i2<<16) + (i3<<8) + i4 ))
}

num_a_ip() {
    local num=$1
    echo "$(( (num>>24)&255 )).$(( (num>>16)&255 )).$(( (num>>8)&255 )).$(( num&255 ))"
}

# ==========================
# INSTALACION SILENCIOSA
# ==========================

instalar_dhcp() {

    rpm -q dhcp-server &> /dev/null
    if [ $? -eq 0 ]; then
        echo "DHCP ya esta instalado."
        read -p "Desea reinstalar? (s/n): " resp
        [[ $resp == "s" ]] && dnf reinstall -y dhcp-server &> /dev/null
    else
        echo "Instalando DHCP..."
        dnf install -y dhcp-server &> /dev/null
    fi

    systemctl enable dhcpd &> /dev/null
    echo "Proceso completado."
}

# ==========================
# CONFIGURACION DHCP
# ==========================

configurar_dhcp() {

    if ! ip link show $INTERFAZ &> /dev/null; then
        echo "No existe la interfaz $INTERFAZ"
        return
    fi

    echo "Configurando DHCP en interfaz $INTERFAZ"

    # ===== Nombre del Ambito =====
    while true; do
        read -p "Nombre del Ambito (scope): " scope
        [ -n "$scope" ] && break
        echo "El nombre del ambito no puede estar vacio."
    done

    # ===== IP Inicial =====
    while true; do
        read -p "IP inicial del rango: " ip_inicio
        ip_valida "$ip_inicio" && break
        echo "IP invalida. Intente nuevamente."
    done

    # ===== IP Final =====
    while true; do
        read -p "IP final del rango: " ip_fin
        ip_valida "$ip_fin" || { echo "IP invalida."; continue; }

        if [ $(ip_a_num $ip_inicio) -lt $(ip_a_num $ip_fin) ]; then
            break
        else
            echo "La IP inicial debe ser menor que la final."
        fi
    done

    # ===== Mascara =====
    read -p "Mascara de red (ENTER para 255.255.255.0): " mascara
    [ -z "$mascara" ] && mascara="255.255.255.0"

    # ===== Gateway =====
    read -p "Gateway (opcional ENTER para omitir): " gateway
    if [ ! -z "$gateway" ]; then
        ip_valida "$gateway" || { echo "Gateway invalido."; return; }
    fi

    # ===== DNS =====
    read -p "DNS (opcional ENTER para omitir): " dns
    if [ ! -z "$dns" ]; then
        ip_valida "$dns" || { echo "DNS invalido."; return; }
    fi

    # ===== Tiempo =====
    while true; do
        read -p "Tiempo de concesion (segundos): " tiempo
        [[ "$tiempo" =~ ^[0-9]+$ ]] && break
        echo "Debe ser un numero valido en segundos."
    done

    servidor_ip=$ip_inicio
    cliente_inicio=$(num_a_ip $(( $(ip_a_num $ip_inicio) + 1 )))

    nmcli connection modify $INTERFAZ ipv4.method manual ipv4.addresses $servidor_ip/24 &> /dev/null
    nmcli connection up $INTERFAZ &> /dev/null

    echo "INTERFACESv4=\"$INTERFAZ\"" > /etc/sysconfig/dhcpd

cat > /etc/dhcp/dhcpd.conf <<EOF
# ==========================================
# Ambito DHCP: $scope
# ==========================================

default-lease-time $tiempo;
max-lease-time $((tiempo*2));
authoritative;

subnet $(echo $ip_inicio | cut -d. -f1-3).0 netmask $mascara {
    range $cliente_inicio $ip_fin;
    $( [ ! -z "$gateway" ] && echo "option routers $gateway;" )
    $( [ ! -z "$dns" ] && echo "option domain-name-servers $dns;" )
}
EOF

    dhcpd -t -cf /etc/dhcp/dhcpd.conf
    if [ $? -ne 0 ]; then
        echo "Error en configuracion."
        return
    fi

    systemctl restart dhcpd &> /dev/null

    if systemctl is-active --quiet dhcpd; then
        echo "DHCP configurado correctamente."
        echo "Ambito: $scope"
        echo "IP Servidor: $servidor_ip"
        echo "Rango Clientes: $cliente_inicio - $ip_fin"
    else
        echo "Error al iniciar DHCP."
    fi
}

# ==========================
# VERIFICAR Y MONITOREAR
# ==========================

verificar_dhcp() {
    rpm -q dhcp-server &> /dev/null && echo "DHCP instalado." || echo "DHCP no instalado."
    systemctl status dhcpd --no-pager
}

monitorear_dhcp() {
    journalctl -u dhcpd -f
}

# ==========================
# MENU
# ==========================

check_root
check_dependencies

while true
do
    clear
    echo "========== DHCP AUTOMATIZADO =========="
    echo "Version $VERSION"
    echo "Interfaz fija: $INTERFAZ (Red Interna red_sistemas)"
    echo "======================================="
    echo "1. Verificar Instalacion"
    echo "2. Instalar/Reinstalar DHCP"
    echo "3. Configurar DHCP"
    echo "4. Monitorear DHCP"
    echo "5. Salir"
    echo "======================================="
    read -p "Seleccione opcion: " op

    case $op in
        1) verificar_dhcp; read -p "ENTER para continuar" ;;
        2) instalar_dhcp; read -p "ENTER para continuar" ;;
        3) configurar_dhcp; read -p "ENTER para continuar" ;;
        4) monitorear_dhcp ;;
        5) exit ;;
        *) echo "Opcion invalida"; sleep 2 ;;
    esac
done
