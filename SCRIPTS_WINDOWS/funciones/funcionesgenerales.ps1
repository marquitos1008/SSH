# ==========================================
# FuncionesGenerales.ps1
# Funciones generales reutilizables para todos los scripts
# ==========================================

# Pausa la ejecución hasta que el usuario presione Enter
function Pause {
    Write-Host ""
    Read-Host "Presiona ENTER para continuar"
}

# Verifica si el script se está ejecutando como Administrador (root en Windows)
function Check-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Este script requiere permisos de Administrador. Por favor, ejecútalo como Administrador." -ForegroundColor Red
        Pause
        exit
    }
}

# Validar IP (reutilizable en DHCP y DNS)
function Validar-IP {
    param($ip)

    if ($ip -match "^([0-9]{1,3}\.){3}[0-9]{1,3}$") {
        $octetos = $ip.Split(".")
        foreach ($o in $octetos) { if ([int]$o -gt 255) { return $false } }
        if ($ip -eq "0.0.0.0" -or $ip -like "127.*") { return $false }
        return $true
    }
    return $false
}

# Obtener la IP de un adaptador (útil para SSH o scripts que requieren IP del servidor)
function Obtener-IPAdaptador {
    param(
        [string]$Adaptador = "Ethernet"
    )
    $ipconfig = Get-NetIPAddress -InterfaceAlias $Adaptador -AddressFamily IPv4 |
                Where-Object { $_.PrefixOrigin -eq "Manual" }
    if ($ipconfig) { return $ipconfig.IPAddress }
    else { return $null }
}