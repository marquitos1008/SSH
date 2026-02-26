# ==========================================
# MainDNS.ps1
# Menú principal que llama a las funciones DNS
# ==========================================

# Cargar funciones desde la carpeta Funciones
Get-ChildItem -Path .\Funciones\*.ps1 | ForEach-Object { . $_.FullName }

while ($true) {
    Clear-Host
    Write-Host "====== MENU DNS (Windows Server 2022) ======"
    Write-Host "1) Ver estado del servicio"
    Write-Host "2) Instalar / Reinstalar DNS"
    Write-Host "3) Administrar dominios (ABC)"
    Write-Host "4) Monitorear"
    Write-Host "5) Salir"

    $op = Read-Host "Opción"

    switch ($op) {
        1 { Estado-DNS }
        2 { Instalar-DNS }
        3 { Administrar-Dominios }
        4 { Monitorear-DNS }
        5 { break }
        default { Write-Host "Opción inválida"; Pause }
    }
}