<#
.SYNOPSIS
    Módulo de Seguridad de SYSCLIPSE.
.DESCRIPTION
    Audita la seguridad del sistema: Windows Defender, firewall, cuentas
    de usuario, políticas de contraseñas, actualizaciones, puertos abiertos,
    UAC, BitLocker y carpetas compartidas.
.NOTES
    Versión : 1.1.0
    Autor   : SYSCLIPSE
#>

<#
.SYNOPSIS
    Obtiene las cuentas de usuario locales del sistema.
#>
function Obtener-CuentasUsuario {
    [CmdletBinding()]
    [OutputType([array])]
    param ()
    try {
        return Get-LocalUser -ErrorAction Stop | Select-Object Name, Enabled, LastLogon
    }
    catch { return @() }
}

<#
.SYNOPSIS
    Obtiene los puertos TCP en escucha.
#>
function Obtener-PuertosAbiertos {
    [CmdletBinding()]
    [OutputType([array])]
    param ()
    try {
        return Get-NetTCPConnection -State Listen -ErrorAction Stop | Select-Object LocalAddress, LocalPort, OwningProcess
    }
    catch { return @() }
}

<#
.SYNOPSIS
    Comprueba el estado del Control de Cuentas de Usuario (UAC).
#>
function Obtener-EstadoUAC {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param ()
    $estado = @{ Habilitado = $false; NivelNotificacion = 0 }
    try {
        $clave = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
        if (Test-Path $clave) {
            $props = Get-ItemProperty -Path $clave -ErrorAction Stop
            $estado.Habilitado = ($props.EnableLUA -eq 1)
            $estado.NivelNotificacion = [int]$props.ConsentPromptBehaviorAdmin
        }
    }
    catch { }
    return $estado
}

<#
.SYNOPSIS
    Comprueba el estado de cifrado BitLocker en todas las unidades.
#>
function Obtener-EstadoBitLocker {
    [CmdletBinding()]
    [OutputType([array])]
    param ()
    $resultado = @()
    try {
        $volumes = Get-BitLockerVolume -ErrorAction Stop
        foreach ($v in $volumes) {
            $resultado += @{
                Unidad        = $v.MountPoint
                Estado        = $v.VolumeStatus.ToString()
                Cifrado       = ($v.EncryptionPercentage)
                Proteccion    = $v.ProtectionStatus.ToString()
            }
        }
    }
    catch { }
    return $resultado
}

<#
.SYNOPSIS
    Obtiene las carpetas compartidas del sistema.
#>
function Obtener-CarpetasCompartidas {
    [CmdletBinding()]
    [OutputType([array])]
    param ()
    $resultado = @()
    try {
        $shares = Get-SmbShare -ErrorAction Stop | Where-Object { $_.Name -notlike '*$' -and $_.Name -ne 'IPC$' }
        foreach ($s in $shares) {
            $resultado += @{
                Nombre   = $s.Name
                Ruta     = $s.Path
                Descripcion = $s.Description
            }
        }
    }
    catch { }
    return $resultado
}

<#
.SYNOPSIS
    Obtiene la política de contraseñas local.
#>
function Obtener-PoliticaContrasenas {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param ()
    $politica = @{
        LongitudMinima    = 0
        Complejidad       = $false
        Historia          = 0
        EdadMaximaDias    = 0
        EdadMinimaDias    = 0
    }
    try {
        $salida = net accounts 2>$null
        if ($salida) {
            foreach ($linea in $salida) {
                if ($linea -match 'Longitud mínima de contraseña') {
                    $politica.LongitudMinima = [int]($linea -replace '.*:\s*', '').Trim()
                }
                elseif ($linea -match 'Historial de contraseñas guardadas') {
                    $politica.Historia = [int]($linea -replace '.*:\s*', '').Trim()
                }
                elseif ($linea -match 'Edad máxima') {
                    $politica.EdadMaximaDias = [int]($linea -replace '.*:\s*', '').Trim()
                }
                elseif ($linea -match 'Edad mínima') {
                    $politica.EdadMinimaDias = [int]($linea -replace '.*:\s*', '').Trim()
                }
            }
        }
    }
    catch { }
    return $politica
}

<#
.SYNOPSIS
    Obtiene el historial reciente de actualizaciones instaladas.
#>
function Obtener-HistorialActualizaciones {
    [CmdletBinding()]
    [OutputType([array])]
    param ()
    $historial = @()
    try {
        $sesion = New-Object -ComObject Microsoft.Update.Session
        $buscador = $sesion.CreateUpdateSearcher()
        $count = $buscador.GetTotalHistoryCount()
        if ($count -gt 0) {
            $resultados = $buscador.QueryHistory(0, [math]::Min($count, 10))
            foreach ($r in $resultados) {
                $historial += @{
                    Titulo  = $r.Title
                    Fecha   = $r.Date.ToString('yyyy-MM-dd HH:mm')
                    Estado  = switch ($r.ResultCode) {
                        1 { 'En progreso' }
                        2 { 'Correcto' }
                        3 { 'Parcial' }
                        4 { 'Fallido' }
                        default { 'Desconocido' }
                    }
                }
            }
        }
    }
    catch { }
    return $historial
}

<#
.SYNOPSIS
    Punto de entrada del módulo de Seguridad.
#>
function Invoke-Seguridad {
    [CmdletBinding()]
    param ()
    Preparar-Consola
    Mostrar-Titulo -Titulo 'AUDITORÍA DE SEGURIDAD' -Ancho 70
    Escribir-Color -Texto 'Auditando la seguridad del sistema...' -Color Azul
    Escribir-Color -Texto '' -Color Gris

    $defender = Obtener-EstadoDefender
    $firewall = Obtener-EstadoFirewall
    $usuarios = Obtener-CuentasUsuario
    $puertos = Obtener-PuertosAbiertos
    $actualizaciones = Obtener-ActualizacionesPendientes
    $uac = Obtener-EstadoUAC
    $bitlocker = Obtener-EstadoBitLocker
    $compartidas = Obtener-CarpetasCompartidas
    $politica = Obtener-PoliticaContrasenas
    $historial = Obtener-HistorialActualizaciones

    Mostrar-Titulo -Titulo 'PROTECCIÓN DEL SISTEMA' -Ancho 70
    Mostrar-Etiqueta -Etiqueta 'Defender activo' -Valor $(if ($defender.Activo) { 'Sí' } else { 'No' }) -ColorValor $(if ($defender.Activo) { 'Verde' } else { 'Rojo' })
    Mostrar-Etiqueta -Etiqueta 'Protección tiempo real' -Valor $(if ($defender.ProteccionTiempoReal) { 'Activa' } else { 'Inactiva' }) -ColorValor $(if ($defender.ProteccionTiempoReal) { 'Verde' } else { 'Rojo' })
    Mostrar-Etiqueta -Etiqueta 'Definiciones antivirus' -Valor $(if ($defender.DefinicionesActualizadas) { 'Actualizadas' } else { 'Pendientes' }) -ColorValor $(if ($defender.DefinicionesActualizadas) { 'Verde' } else { 'Amarillo' })
    Mostrar-Etiqueta -Etiqueta 'Firewall dominio' -Valor $(if ($firewall.PerfilDominio) { 'Activo' } else { 'Inactivo' }) -ColorValor $(if ($firewall.PerfilDominio) { 'Verde' } else { 'Rojo' })
    Mostrar-Etiqueta -Etiqueta 'Firewall privado' -Valor $(if ($firewall.PerfilPrivado) { 'Activo' } else { 'Inactivo' }) -ColorValor $(if ($firewall.PerfilPrivado) { 'Verde' } else { 'Rojo' })
    Mostrar-Etiqueta -Etiqueta 'Firewall público' -Valor $(if ($firewall.PerfilPublico) { 'Activo' } else { 'Inactivo' }) -ColorValor $(if ($firewall.PerfilPublico) { 'Verde' } else { 'Rojo' })
    Mostrar-Etiqueta -Etiqueta 'UAC habilitado' -Valor $(if ($uac.Habilitado) { 'Sí' } else { 'No' }) -ColorValor $(if ($uac.Habilitado) { 'Verde' } else { 'Rojo' })
    Mostrar-Separador -Ancho 70 -Color Gris

    Mostrar-Titulo -Titulo 'CUENTAS DE USUARIO' -Ancho 70
    if ($usuarios.Count -eq 0) {
        Mostrar-Aviso -Mensaje 'No se pudieron obtener las cuentas de usuario.'
    }
    else {
        foreach ($u in $usuarios) {
            $estado = if ($u.Enabled) { 'Habilitada' } else { 'Deshabilitada' }
            $color = if ($u.Enabled) { 'Blanco' } else { 'Gris' }
            Mostrar-Etiqueta -Etiqueta $u.Name -Valor $estado -ColorValor $color
        }
    }
    Mostrar-Separador -Ancho 70 -Color Gris

    Mostrar-Titulo -Titulo 'POLÍTICA DE CONTRASEÑAS' -Ancho 70
    Mostrar-Etiqueta -Etiqueta 'Longitud mínima' -Valor "$($politica.LongitudMinima) caracteres" -ColorValor $(if ($politica.LongitudMinima -ge 8) { 'Verde' } elseif ($politica.LongitudMinima -gt 0) { 'Amarillo' } else { 'Rojo' })
    Mostrar-Etiqueta -Etiqueta 'Historial' -Valor "$($politica.Historia) contraseñas" -ColorValor $(if ($politica.Historia -ge 5) { 'Verde' } elseif ($politica.Historia -gt 0) { 'Amarillo' } else { 'Rojo' })
    Mostrar-Etiqueta -Etiqueta 'Edad máxima' -Valor "$($politica.EdadMaximaDias) días" -ColorValor $(if ($politica.EdadMaximaDias -gt 0 -and $politica.EdadMaximaDias -le 90) { 'Verde' } else { 'Amarillo' })
    Mostrar-Etiqueta -Etiqueta 'Edad mínima' -Valor "$($politica.EdadMinimaDias) días" -ColorValor Blanco
    Mostrar-Separador -Ancho 70 -Color Gris

    Mostrar-Titulo -Titulo 'CIFRADO BITLOCKER' -Ancho 70
    if ($bitlocker.Count -eq 0) {
        Mostrar-Aviso -Mensaje 'No se pudo obtener el estado de BitLocker.'
    }
    else {
        foreach ($b in $bitlocker) {
            $valor = "$($b.Cifrado)% - $($b.Estado) ($($b.Proteccion))"
            $color = if ($b.Proteccion -eq 'On' -and $b.Cifrado -eq 100) { 'Verde' } elseif ($b.Cifrado -gt 0) { 'Amarillo' } else { 'Rojo' }
            Mostrar-Etiqueta -Etiqueta "Unidad $($b.Unidad)" -Valor $valor -ColorValor $color
        }
    }
    Mostrar-Separador -Ancho 70 -Color Gris

    Mostrar-Titulo -Titulo 'CARPETAS COMPARTIDAS' -Ancho 70
    if ($compartidas.Count -eq 0) {
        Mostrar-Correcto -Mensaje 'No hay carpetas compartidas (excluyendo recursos administrativos).'
    }
    else {
        Mostrar-Etiqueta -Etiqueta 'Total' -Valor $compartidas.Count -ColorValor $(if ($compartidas.Count -gt 5) { 'Amarillo' } else { 'Blanco' })
        foreach ($c in $compartidas) {
            Mostrar-Etiqueta -Etiqueta "  $($c.Nombre)" -Valor $c.Ruta -ColorValor Blanco
        }
    }
    Mostrar-Separador -Ancho 70 -Color Gris

    Mostrar-Titulo -Titulo 'PUERTOS EN ESCUCHA' -Ancho 70
    if ($puertos.Count -eq 0) {
        Mostrar-Aviso -Mensaje 'No se pudieron obtener los puertos abiertos.'
    }
    else {
        Mostrar-Etiqueta -Etiqueta 'Total de puertos' -Valor $puertos.Count -ColorValor $(if ($puertos.Count -gt 20) { 'Amarillo' } else { 'Blanco' })
        $primeros = $puertos | Select-Object -First 10
        foreach ($p in $primeros) {
            Mostrar-Etiqueta -Etiqueta ("  {0}:{1}" -f $p.LocalAddress, $p.LocalPort) -Valor "PID $($p.OwningProcess)" -ColorValor Blanco
        }
        if ($puertos.Count -gt 10) {
            Mostrar-Info -Mensaje "  ... y $($puertos.Count - 10) puerto(s) más."
        }
    }
    Mostrar-Separador -Ancho 70 -Color Gris

    Mostrar-Titulo -Titulo 'ACTUALIZACIONES' -Ancho 70
    Mostrar-Etiqueta -Etiqueta 'Pendientes de reinicio' -Valor $actualizaciones -ColorValor $(if ($actualizaciones -gt 0) { 'Amarillo' } else { 'Verde' })
    if ($historial.Count -gt 0) {
        Escribir-Color -Texto '' -Color Gris
        Escribir-Color -Texto '  Últimas actualizaciones instaladas:' -Color Cian
        foreach ($h in $historial) {
            $color = if ($h.Estado -eq 'Correcto') { 'Verde' } elseif ($h.Estado -eq 'Fallido') { 'Rojo' } else { 'Amarillo' }
            Mostrar-Etiqueta -Etiqueta "  $($h.Fecha)" -Valor "$($h.Titulo) [$($h.Estado)]" -ColorValor $color
        }
    }
    else {
        Mostrar-Aviso -Mensaje 'No se pudo obtener el historial de actualizaciones.'
    }
    Mostrar-Separador -Ancho 70 -Color Gris

    Escribir-Registro -Mensaje 'Auditoría de seguridad completada.' -Nivel INFO
    Esperar-Tecla
}

Export-ModuleMember -Function Obtener-CuentasUsuario, Obtener-PuertosAbiertos, Obtener-EstadoUAC, `
    Obtener-EstadoBitLocker, Obtener-CarpetasCompartidas, Obtener-PoliticaContrasenas, `
    Obtener-HistorialActualizaciones, Invoke-Seguridad
