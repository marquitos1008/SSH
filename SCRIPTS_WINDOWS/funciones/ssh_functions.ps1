# =========================================
# FuncionesSSH
# =========================================

function Verificar-SSH {
    $cap = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
    if ($cap.State -eq "Installed") {
        Write-Host "[OK] OpenSSH Server ya está instalado."
        return $true
    } else {
        Write-Host "[INFO] OpenSSH Server no está instalado."
        return $false
    }
}

function Instalar-SSH {
    Write-Host "Instalando OpenSSH Server..."
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    Write-Host "[OK] Instalación completada."
}

function Configurar-SSH {
    Write-Host "Configurando servicio y firewall SSH..."
    
    # Iniciar y habilitar servicio
    Start-Service sshd
    Set-Service -Name sshd -StartupType 'Automatic'
    
    # Configurar firewall
    if (-not (Get-NetFirewallRule -Name sshd -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' `
            -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
        Write-Host "[OK] Firewall configurado para SSH."
    } else {
        Write-Host "[INFO] La regla de firewall SSH ya existe."
    }

    # Obtener IP del adaptador "Ethernet 3"
    $adapter = Get-NetIPAddress -InterfaceAlias "Ethernet 3" -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if ($adapter) {
        Write-Host "`nPara conectarse desde el cliente (tu máquina real):"
        Write-Host "ssh Administrador@$($adapter.IPAddress)`n"
    } else {
        Write-Host "[WARN] No se encontró el adaptador 'Ethernet 3'. Asegúrate de tenerlo habilitado y configurado."
    }
}

function Verificar-Estado-SSH {
    $service = Get-Service sshd -ErrorAction SilentlyContinue
    if ($service) {
        Write-Host "Estado del servicio SSH:" $service.Status
    } else {
        Write-Host "Servicio SSH no encontrado."
    }
}