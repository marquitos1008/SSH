# ==========================================
# MainMenu.ps1
# Menú principal que llama a DHCP, DNS o SSH
# ==========================================

# Cargar funciones generales si existen
if (Test-Path .\Funciones\FuncionesGenerales.ps1) {
    . .\Funciones\FuncionesGenerales.ps1
}

while ($true) {
    Clear-Host
    Write-Host "====== MENU PRINCIPAL - RED_SISTEMAS ======"
    Write-Host "1) DHCP"
    Write-Host "2) DNS"
    Write-Host "3) SSH"
    Write-Host "4) Salir"

    $op = Read-Host "Selecciona una opción"

    switch ($op) {
        1 { 
            if (Test-Path .\main_dhcp.ps1) { 
                . .\main_dhcp.ps1 
            } 
            else { 
                Write-Host "main_dhcp.ps1 no encontrado"
                Pause
            }
        }
        2 { 
            if (Test-Path .\main_dns.ps1) { 
                . .\main_dns.ps1 
            } 
            else { 
                Write-Host "main_dns.ps1 no encontrado"
                Pause
            }
        }
        3 { 
            if (Test-Path .\main_ssh.ps1) { 
                . .\main_ssh.ps1 
            } 
            else { 
                Write-Host "main_ssh.ps1 no encontrado"
                Pause
            }
        }
        4 { break }
        default { 
            Write-Host "Opción inválida"
            Pause
        }
    }
}