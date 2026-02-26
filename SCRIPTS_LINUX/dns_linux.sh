#!/bin/bash

ARCHIVO_IP="/var/lib/red_sistemas/dhcp_server_ip"
ZONAS="/etc/named.rfc1912.zones"
DIR_ZONAS="/var/named"

pause() {
  read -p "Presiona ENTER para continuar..."
}

# =========================
obtener_ip_servidor() {
  if [ ! -f "$ARCHIVO_IP" ]; then
    echo "ERROR: No se encontró la IP del servidor DHCP."
    echo "Configura primero el DHCP."
    exit 1
  fi
  IP_SERVIDOR=$(cat "$ARCHIVO_IP")
}

validar_ip() {
  [[ $1 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
  case "$1" in
    127.*|0.0.0.0|255.255.255.255) return 1 ;;
  esac
  return 0
}

# =========================
estado_dns() {
  echo "===== ESTADO DNS ====="
  if rpm -q bind &>/dev/null; then
    echo "BIND instalado"
  else
    echo "BIND NO instalado"
  fi

  if systemctl is-active named &>/dev/null; then
    echo "Servicio DNS: ACTIVO"
  else
    echo "Servicio DNS: INACTIVO"
  fi
  pause
}

# =========================
instalar_dns() {
  echo "===== INSTALAR / REINSTALAR DNS ====="
  dnf install -y bind bind-utils
  systemctl enable named
  pause
}

# =========================
configurar_dns_base() {
  obtener_ip_servidor

  cat > /etc/named.conf <<EOF
options {
    listen-on port 53 { 127.0.0.1; $IP_SERVIDOR; };
    directory "$DIR_ZONAS";
    allow-query { any; };
    recursion yes;
    dnssec-validation no;
};

include "$ZONAS";
EOF

  systemctl restart named
}

# =========================
agregar_dominio() {
  obtener_ip_servidor

  read -p "Nombre del dominio (ej. coca.com): " DOMINIO
  read -p "IP del dominio (Enter = IP del servidor): " IP_DOM
  IP_DOM=${IP_DOM:-$IP_SERVIDOR}

  validar_ip "$IP_DOM" || { echo "IP inválida"; pause; return; }

  ARCHIVO_ZONA="$DIR_ZONAS/db.$DOMINIO"

  if grep -q "zone \"$DOMINIO\"" "$ZONAS"; then
    echo "El dominio ya existe"
    pause
    return
  fi

  cat > "$ARCHIVO_ZONA" <<EOF
\$TTL 1D
@   IN SOA ns1.$DOMINIO. admin.$DOMINIO. (
        $(date +%Y%m%d%H)
        1H
        15M
        1W
        1D )

    IN NS ns1.$DOMINIO.
ns1 IN A $IP_SERVIDOR
@   IN A $IP_DOM
EOF

  echo "
zone \"$DOMINIO\" IN {
    type master;
    file \"db.$DOMINIO\";
};" >> "$ZONAS"

  chown root:named "$ARCHIVO_ZONA"
  chmod 640 "$ARCHIVO_ZONA"

  systemctl restart named

  echo "Dominio agregado correctamente"
  pause
}

# =========================
eliminar_dominio() {
  read -p "Dominio a eliminar: " DOMINIO

  sed -i "/zone \"$DOMINIO\"/,/};/d" "$ZONAS"
  rm -f "$DIR_ZONAS/db.$DOMINIO"

  systemctl restart named

  echo "Dominio eliminado"
  pause
}

# =========================
listar_dominios() {
  echo "===== DOMINIOS CONFIGURADOS ====="
  for Z in $DIR_ZONAS/db.*; do
    [ -e "$Z" ] || continue
    DOM=$(basename "$Z" | sed 's/db\.//')
    IP=$(grep -E "^[^;].*IN A" "$Z" | head -n1 | awk '{print $NF}')
    printf "%-25s -> %s\n" "$DOM" "$IP"
  done
  pause
}

# =========================
monitorear_dns() {
  echo "===== MONITOREO DNS ====="

  if ! systemctl is-active named &>/dev/null; then
    echo "DNS apagado → iniciando..."
    systemctl start named
  fi

  if systemctl is-active named &>/dev/null; then
    echo "Servicio DNS ACTIVO"
  else
    echo "ERROR: DNS no pudo iniciar"
  fi

  pause
}

# =========================
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
  echo "8) Salir"
  read -p "Opción: " OP

  case $OP in
    1) estado_dns ;;
    2) instalar_dns ;;
    3) configurar_dns_base ;;
    4) agregar_dominio ;;
    5) eliminar_dominio ;;
    6) listar_dominios ;;
    7) monitorear_dns ;;
    8) exit ;;
    *) echo "Opción inválida"; pause ;;
  esac
done