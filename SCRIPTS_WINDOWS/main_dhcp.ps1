# ==========================================
# MainDHCP.ps1
# Menú principal que llama a las funciones DHCP
# ==========================================

# Cargar funciones desde la carpeta Funciones
Get-ChildItem -Path .\Funciones\*.ps1 | ForEach-Object { . $_.FullName }

while ($true) {
    Clear-Host
    Write-Host "====== MENU DHCP (Windows Server 2022) ======"
    Write-Host "1) Ver estado del servicio"
    Write-Host "2) Instalar / Reinstalar DHCP"
    Write-Host "3) Configurar DHCP"
    Write-Host "4) Monitorear"
    Write-Host "5) Salir"

    $op = Read-Host "Opción"

    switch ($op) {
        1 { Estado-DHCP }
        2 { Instalar-DHCP }
        3 { Configurar-DHCP }
        4 { Monitorear-DHCP }
        5 { exit }
        default { Write-Host "Opción inválida"; Pause }
    }
}