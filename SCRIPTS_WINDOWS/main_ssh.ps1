# =========================================
# MainSSH.ps1
# Menú principal para administrar SSH en Windows Server
# =========================================

# Cargar funciones
. .\FuncionesSSH.ps1

do {
    Write-Host ""
    Write-Host "===== MENÚ SSH WINDOWS SERVER ====="
    Write-Host "1. Verificar instalación de SSH"
    Write-Host "2. Instalar OpenSSH Server"
    Write-Host "3. Configurar servicio y firewall SSH"
    Write-Host "4. Verificar estado del servicio SSH"
    Write-Host "5. Salir"
    Write-Host "==================================="
    
    $opcion = Read-Host "Seleccione una opción"

    switch ($opcion) {
        "1" { Verificar-SSH }
        "2" { Instalar-SSH }
        "3" { Configurar-SSH }
        "4" { Verificar-Estado-SSH }
        "5" { Write-Host "Saliendo..."; break }
        default { Write-Host "Opción inválida. Intente de nuevo." }
    }
} while ($true)