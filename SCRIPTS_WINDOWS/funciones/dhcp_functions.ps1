# ==============================================
# FuncionesDHCP.ps1
# Bibliotecas de funciones DHCP para Windows Server 2022
# ==============================================

$Adaptador = "Ethernet"

function Pause {
    Write-Host ""
    Read-Host "Presiona ENTER para continuar"
}

# ---------------- VALIDACIONES ----------------
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

function Obtener-Mascara-Sugerida {
    param($ip)

    $primerOcteto = [int]($ip.Split(".")[0])

    if ($primerOcteto -ge 1 -and $primerOcteto -le 126) { return "255.0.0.0" }
    elseif ($primerOcteto -ge 128 -and $primerOcteto -le 191) { return "255.255.0.0" }
    elseif ($primerOcteto -ge 192 -and $primerOcteto -le 223) { return "255.255.255.0" }
    else { return "255.255.255.0" }
}

# ---------------- ESTADO ----------------
function Estado-DHCP {
    Write-Host "===== ESTADO DHCP ====="
    $feature = Get-WindowsFeature -Name DHCP
    if ($feature.Installed) { Write-Host "Rol DHCP: INSTALADO" } else { Write-Host "Rol DHCP: NO instalado" }

    $service = Get-Service -Name DHCPServer -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq "Running") { Write-Host "Servicio DHCP: ACTIVO" } else { Write-Host "Servicio DHCP: INACTIVO" }

    Pause
}

# ---------------- INSTALAR ----------------
function Instalar-DHCP {
    Write-Host "===== INSTALAR / REINSTALAR DHCP ====="
    Install-WindowsFeature DHCP -IncludeManagementTools
    netsh dhcp add securitygroups
    Restart-Service DHCPServer -ErrorAction SilentlyContinue
    Write-Host "DHCP instalado correctamente."
    Pause
}

# ---------------- CONFIGURAR ----------------
function Configurar-DHCP {
    Write-Host "===== CONFIGURAR DHCP ====="

    $ScopeName = Read-Host "Nombre del Scope"

    while ($true) { $IPInicio = Read-Host "IP inicial (será IP del servidor)"; if (Validar-IP $IPInicio) { break }; Write-Host "IP inválida" }
    while ($true) { $IPFin = Read-Host "IP final del rango"; if (Validar-IP $IPFin) { break }; Write-Host "IP inválida" }

    $MascaraSugerida = Obtener-Mascara-Sugerida $IPInicio
    $Mascara = Read-Host "Máscara de red (Enter=$MascaraSugerida)"
    if ([string]::IsNullOrWhiteSpace($Mascara)) { $Mascara = $MascaraSugerida }

    $Gateway = Read-Host "Gateway (opcional, Enter vacío)"
    $Lease = Read-Host "Tiempo de concesión (segundos)"

    # DNS secundaria opcional
    $DNS2 = Read-Host "DNS secundaria (opcional, Enter vacío)"

    try {
        Write-Host "Configurando IP fija al servidor..."

        switch ($Mascara) {
            "255.0.0.0"       { $prefijo = 8 }
            "255.255.0.0"     { $prefijo = 16 }
            "255.255.255.0"   { $prefijo = 24 }
            default { Write-Host "Máscara no soportada automáticamente."; return }
        }

        $ipsExistentes = Get-NetIPAddress -InterfaceAlias $Adaptador -AddressFamily IPv4 -ErrorAction SilentlyContinue
        if ($ipsExistentes) { $ipsExistentes | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue }

        if (![string]::IsNullOrWhiteSpace($Gateway)) {
            New-NetIPAddress -InterfaceAlias $Adaptador -IPAddress $IPInicio -PrefixLength $prefijo -DefaultGateway $Gateway -ErrorAction Stop
        } else {
            New-NetIPAddress -InterfaceAlias $Adaptador -IPAddress $IPInicio -PrefixLength $prefijo -ErrorAction Stop
        }

        # Ajustar DNS: primaria + secundaria opcional
        if (![string]::IsNullOrWhiteSpace($DNS2)) {
            Set-DnsClientServerAddress -InterfaceAlias $Adaptador -ServerAddresses @($IPInicio,$DNS2)
        } else {
            Set-DnsClientServerAddress -InterfaceAlias $Adaptador -ServerAddresses $IPInicio
        }

        Restart-Service DHCPServer -ErrorAction SilentlyContinue

        Set-DhcpServerv4Binding -InterfaceAlias $Adaptador -BindingState $true -ErrorAction SilentlyContinue

        # Eliminar scopes anteriores
        $Scopes = Get-DhcpServerv4Scope -ErrorAction SilentlyContinue
        if ($Scopes) { foreach ($s in $Scopes) { Remove-DhcpServerv4Scope -ScopeId $s.ScopeId -Force -ErrorAction SilentlyContinue } }

        # Calcular rango
        $octetos = $IPInicio.Split(".")
        $ultimoOcteto = [int]$octetos[3]
        $RangoInicio = "$($octetos[0]).$($octetos[1]).$($octetos[2]).$($ultimoOcteto + 1)"

        # Crear scope
        Add-DhcpServerv4Scope -Name $ScopeName -StartRange $RangoInicio -EndRange $IPFin -SubnetMask $Mascara -State Active -ErrorAction Stop

        $ScopeCreado = Get-DhcpServerv4Scope | Where-Object { $_.Name -eq $ScopeName }
        $ScopeId = $ScopeCreado.ScopeId

        # Opciones de Scope
        Set-DhcpServerv4OptionValue -ScopeId $ScopeId -DnsServer $IPInicio -Force
        if (![string]::IsNullOrWhiteSpace($DNS2)) { Set-DhcpServerv4OptionValue -ScopeId $ScopeId -DnsServer $DNS2 -Force }

        Set-DhcpServerv4OptionValue -ScopeId $ScopeId -DnsDomain "reprobados.com" -Force
        if ($Gateway) { Set-DhcpServerv4OptionValue -ScopeId $ScopeId -Router $Gateway }

        Set-DhcpServerv4Scope -ScopeId $ScopeId -LeaseDuration (New-TimeSpan -Seconds $Lease)

        Write-Host ""
        Write-Host "DHCP configurado correctamente."
    } catch {
        Write-Host ""
        Write-Host "ERROR durante la configuración:"
        Write-Host $_.Exception.Message
    }

    Pause
}

# ---------------- MONITOREO ----------------
function Monitorear-DHCP {
    Write-Host "===== MONITOREO DHCP ====="
    if ((Get-Service DHCPServer).Status -ne "Running") { Start-Service DHCPServer }

    $scope = Get-DhcpServerv4Scope -ErrorAction SilentlyContinue

    if ($scope) {
        Write-Host ""
        Write-Host "Scopes activos:"
        $scope | Format-Table ScopeId, Name, State -AutoSize

        Write-Host ""
        Write-Host "Concesiones activas:"
        Get-DhcpServerv4Lease -ScopeId $scope.ScopeId | Format-Table IPAddress, HostName, ClientId, LeaseExpiryTime -AutoSize
    } else {
        Write-Host "No hay scopes configurados."
    }

    Pause
}