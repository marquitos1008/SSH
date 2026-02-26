# =========================================
# FuncionesSSH.ps1
# Bibliotecas de funciones para instalar y configurar SSH en Windows Server
# =========================================

function Verificar-SSH {
    # Verifica si OpenSSH Server está instalado
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
    # Instala OpenSSH Server
    Write-Host "Instalando OpenSSH Server..."
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    Write-Host "[OK] Instalación completada."
}

function Configurar-SSH {
    # Inicia y habilita el servicio
    Write-Host "Configurando el servicio SSH..."
    Start-Service sshd
    Set-Service -Name sshd -StartupType 'Automatic'
    Write-Host "[OK] Servicio SSH iniciado y configurado para iniciar con Windows."

    # Configura firewall
    if (-not (Get-NetFirewallRule -Name sshd -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' `
            -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
        Write-Host "[OK] Regla de firewall creada para SSH."
    } else {
        Write-Host "[INFO] La regla de firewall SSH ya existe."
    }
}

function Verificar-Estado-SSH {
    # Muestra el estado del servicio SSH
    $service = Get-Service sshd -ErrorAction SilentlyContinue
    if ($service) {
        Write-Host "Servicio SSH Status:" $service.Status
    } else {
        Write-Host "Servicio SSH no encontrado."
    }
}