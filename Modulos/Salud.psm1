<#
.SYNOPSIS
    Módulo de Análisis de Salud de SYSCLIPSE.
.DESCRIPTION
    Implementa el motor de diagnóstico inteligente que evalúa el estado
    general del sistema: CPU, memoria, disco, Windows, SMART, Defender,
    firewall, servicios y arranque. Calcula una puntuación de salud propia
    y genera recomendaciones claras para el usuario.
.NOTES
    Versión : 1.1.0
    Autor   : SYSCLIPSE
#>

<#
.SYNOPSIS
    Obtiene el uso actual del procesador.
#>
function Obtener-UsoCPU {
    [CmdletBinding()]
    [OutputType([int])]
    param ()
    try {
        $cpu = (Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop).LoadPercentage
        if ($null -ne $cpu) { return [int]$cpu }
    }
    catch { }
    return 0
}

<#
.SYNOPSIS
    Obtiene el uso de memoria RAM.
.OUTPUTS
    Hashtable con Total, Libre, Usado y Porcentaje.
#>
function Obtener-UsoMemoria {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param ()
    $mem = @{ Total = 0; Libre = 0; Usado = 0; Porcentaje = 0 }
    try {
        $so = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $mem.Total = [math]::Round($so.TotalVisibleMemorySize / 1MB, 2)
        $mem.Libre = [math]::Round($so.FreePhysicalMemory / 1MB, 2)
        $mem.Usado = $mem.Total - $mem.Libre
        if ($mem.Total -gt 0) {
            $mem.Porcentaje = [int](($mem.Usado / $mem.Total) * 100)
        }
    }
    catch { }
    return $mem
}

<#
.SYNOPSIS
    Obtiene el estado de los discos lógicos.
.OUTPUTS
    Lista de hashtables con Letra, Total, Libre, Porcentaje.
#>
function Obtener-EstadoDiscos {
    [CmdletBinding()]
    [OutputType([array])]
    param ()
    $discos = @()
    try {
        $volumes = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop
        foreach ($v in $volumes) {
            if ($v.Size -gt 0) {
                $porcentaje = [int](($v.FreeSpace / $v.Size) * 100)
                $discos += @{
                    Letra       = $v.DeviceID
                    Total       = [math]::Round($v.Size / 1GB, 2)
                    Libre       = [math]::Round($v.FreeSpace / 1GB, 2)
                    Porcentaje  = $porcentaje
                }
            }
        }
    }
    catch { }
    return $discos
}

<#
.SYNOPSIS
    Comprueba el estado de Windows Defender.
#>
function Obtener-EstadoDefender {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param ()
    $estado = @{ Activo = $false; DefinicionesActualizadas = $false; ProteccionTiempoReal = $false }
    try {
        $def = Get-MpComputerStatus -ErrorAction Stop
        $estado.Activo = $def.AntivirusEnabled
        $estado.ProteccionTiempoReal = $def.RealTimeProtectionEnabled
        $estado.DefinicionesActualizadas = $def.AntivirusSignatureUpToDate
    }
    catch { }
    return $estado
}

<#
.SYNOPSIS
    Comprueba el estado del firewall de Windows.
#>
function Obtener-EstadoFirewall {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param ()
    $estado = @{ PerfilDominio = $false; PerfilPrivado = $false; PerfilPublico = $false }
    try {
        $fw = Get-NetFirewallProfile -ErrorAction Stop
        foreach ($perfil in $fw) {
            switch ($perfil.Name) {
                'Domain'   { $estado.PerfilDominio = $perfil.Enabled }
                'Private'  { $estado.PerfilPrivado = $perfil.Enabled }
                'Public'   { $estado.PerfilPublico = $perfil.Enabled }
            }
        }
    }
    catch { }
    return $estado
}

<#
.SYNOPSIS
    Cuenta los servicios que están configurados para iniciar automáticamente
    pero que no se están ejecutando.
#>
function Obtener-ServiciosParados {
    [CmdletBinding()]
    [OutputType([array])]
    param ()
    $parados = @()
    try {
        $servicios = Get-Service -ErrorAction Stop | Where-Object {
            $_.StartType -eq 'Automatic' -and $_.Status -ne 'Running'
        }
        foreach ($s in $servicios) {
            $parados += $s.Name
        }
    }
    catch { }
    return $parados
}

<#
.SYNOPSIS
    Obtiene el número de aplicaciones que se ejecutan al inicio.
#>
function Obtener-ProgramasInicio {
    [CmdletBinding()]
    [OutputType([array])]
    param ()
    $inicio = @()
    try {
        $claves = @(
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run',
            'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
        )
        foreach ($clave in $claves) {
            if (Test-Path $clave) {
                $props = Get-ItemProperty -Path $clave -ErrorAction SilentlyContinue
                if ($props) {
                    $props.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' } | ForEach-Object {
                        $inicio += $_.Name
                    }
                }
            }
        }
    }
    catch { }
    return $inicio
}

<#
.SYNOPSIS
    Comprueba si hay actualizaciones pendientes de Windows.
#>
function Obtener-ActualizacionesPendientes {
    [CmdletBinding()]
    [OutputType([int])]
    param ()
    try {
        $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
        if (Test-Path $key) { return 1 }
    }
    catch { }
    return 0
}

<#
.SYNOPSIS
    Comprueba el estado SMART de los discos físicos.
#>
function Obtener-EstadoSMART {
    [CmdletBinding()]
    [OutputType([string])]
    param ()
    try {
        $discos = Get-PhysicalDisk -ErrorAction Stop
        foreach ($d in $discos) {
            if ($d.HealthStatus -ne 'Healthy') {
                return 'Degradado'
            }
        }
        return 'Correcto'
    }
    catch {
        return 'No disponible'
    }
}

<#
.SYNOPSIS
    Calcula la puntuación de salud del sistema.
.DESCRIPTION
    Evalúa múltiples dimensiones (rendimiento, seguridad, estabilidad y
    mantenimiento) y devuelve una puntuación global sobre 100 junto con
    el estado textual y el color asociado.
.OUTPUTS
    Hashtable con Puntuacion, Rendimiento, Seguridad, Estabilidad,
    Mantenimiento, EstadoTexto y EstadoColor.
#>
function Obtener-PuntuacionSalud {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param ()
    # Rendimiento: basado en CPU, RAM y espacio en disco.
    $cpu = Obtener-UsoCPU
    $mem = Obtener-UsoMemoria
    $discos = Obtener-EstadoDiscos
    $espacioCritico = $false
    foreach ($d in $discos) {
        if ($d.Porcentaje -lt 10) { $espacioCritico = $true }
    }
    $rendimiento = 100
    $rendimiento -= [int]($cpu * 0.3)
    $rendimiento -= [int]($mem.Porcentaje * 0.3)
    if ($espacioCritico) { $rendimiento -= 15 }
    $rendimiento = [math]::Max(0, [math]::Min(100, $rendimiento))

    # Seguridad: Defender, firewall y actualizaciones.
    $defender = Obtener-EstadoDefender
    $firewall = Obtener-EstadoFirewall
    $seguridad = 100
    if (-not $defender.ProteccionTiempoReal) { $seguridad -= 30 }
    if (-not $defender.DefinicionesActualizadas) { $seguridad -= 15 }
    if (-not $firewall.PerfilPrivado) { $seguridad -= 20 }
    if (-not $firewall.PerfilPublico) { $seguridad -= 15 }
    $seguridad = [math]::Max(0, [math]::Min(100, $seguridad))

    # Estabilidad: servicios parados y SMART.
    $serviciosParados = Obtener-ServiciosParados
    $smart = Obtener-EstadoSMART
    $estabilidad = 100
    $estabilidad -= ($serviciosParados.Count * 3)
    if ($smart -eq 'Degradado') { $estabilidad -= 25 }
    $estabilidad = [math]::Max(0, [math]::Min(100, $estabilidad))

    # Mantenimiento: actualizaciones pendientes y programas de inicio.
    $actualizaciones = Obtener-ActualizacionesPendientes
    $programasInicio = Obtener-ProgramasInicio
    $mantenimiento = 100
    $mantenimiento -= ($actualizaciones * 10)
    $mantenimiento -= ([math]::Max(0, $programasInicio.Count - 5) * 2)
    $mantenimiento = [math]::Max(0, [math]::Min(100, $mantenimiento))

    # Puntuación global ponderada.
    $puntuacion = [int](($rendimiento * 0.30) + ($seguridad * 0.30) + ($estabilidad * 0.25) + ($mantenimiento * 0.15))

    # Estado textual y color.
    $estadoTexto = ''
    $estadoColor = ''
    if     ($puntuacion -ge 90) { $estadoTexto = 'Excelente'; $estadoColor = 'Verde' }
    elseif ($puntuacion -ge 75) { $estadoTexto = 'Bueno';     $estadoColor = 'Verde' }
    elseif ($puntuacion -ge 60) { $estadoTexto = 'Aceptable'; $estadoColor = 'Amarillo' }
    elseif ($puntuacion -ge 40) { $estadoTexto = 'Degradado'; $estadoColor = 'Amarillo' }
    else                        { $estadoTexto = 'Crítico';   $estadoColor = 'Rojo' }

    return @{
        Puntuacion      = $puntuacion
        Rendimiento     = $rendimiento
        Seguridad       = $seguridad
        Estabilidad     = $estabilidad
        Mantenimiento   = $mantenimiento
        EstadoTexto     = $estadoTexto
        EstadoColor      = $estadoColor
    }
}

<#
.SYNOPSIS
    Ejecuta el análisis completo de salud del sistema.
.DESCRIPTION
    Recorre cada subsistema, muestra el progreso en consola, calcula la
    puntuación y genera un resumen con recomendaciones.
#>
function Invoke-Salud {
    [CmdletBinding()]
    param ()
    Preparar-Consola
    Mostrar-Titulo -Titulo 'ANÁLISIS COMPLETO DEL SISTEMA' -Ancho 70
    Escribir-Color -Texto 'Analizando su sistema, por favor espere...' -Color Azul
    Escribir-Color -Texto '' -Color Gris

    $pasos = @(
        'Comprobando Event Viewer...',
        'Comprobando controladores...',
        'Comprobando Windows Defender...',
        'Comprobando Windows Update...',
        'Comprobando servicios...',
        'Comprobando inicio automático...',
        'Comprobando SMART...',
        'Comprobando firewall...',
        'Comprobando DNS...'
    )
    $total = $pasos.Count
    $i = 0
    foreach ($paso in $pasos) {
        $i++
        $porcentaje = [int](($i / $total) * 100)
        Mostrar-Progreso -Tarea $paso -Porcentaje $porcentaje
        Start-Sleep -Milliseconds 250
    }
    Escribir-Color -Texto '' -Color Gris
    Mostrar-Correcto -Mensaje 'Análisis completado.'
    Escribir-Color -Texto '' -Color Gris

    # Recopilación de resultados.
    $cpu = Obtener-UsoCPU
    $mem = Obtener-UsoMemoria
    $discos = Obtener-EstadoDiscos
    $defender = Obtener-EstadoDefender
    $firewall = Obtener-EstadoFirewall
    $serviciosParados = Obtener-ServiciosParados
    $programasInicio = Obtener-ProgramasInicio
    $actualizaciones = Obtener-ActualizacionesPendientes
    $smart = Obtener-EstadoSMART
    $puntuacion = Obtener-PuntuacionSalud

    # Resumen de puntuación.
    Mostrar-Titulo -Titulo 'RESUMEN DE SALUD' -Ancho 70
    Mostrar-Etiqueta -Etiqueta 'Puntuación global' -Valor ("{0}/100" -f $puntuacion.Puntuacion) -ColorValor $puntuacion.EstadoColor
    Mostrar-Etiqueta -Etiqueta 'Estado' -Valor $puntuacion.EstadoTexto -ColorValor $puntuacion.EstadoColor
    Mostrar-Etiqueta -Etiqueta 'Rendimiento' -Valor ("{0}%" -f $puntuacion.Rendimiento) -ColorValor Blanco
    Mostrar-Etiqueta -Etiqueta 'Seguridad' -Valor ("{0}%" -f $puntuacion.Seguridad) -ColorValor Blanco
    Mostrar-Etiqueta -Etiqueta 'Estabilidad' -Valor ("{0}%" -f $puntuacion.Estabilidad) -ColorValor Blanco
    Mostrar-Etiqueta -Etiqueta 'Mantenimiento' -Valor ("{0}%" -f $puntuacion.Mantenimiento) -ColorValor Blanco
    Mostrar-Separador -Ancho 70 -Color Gris

    # Detalle de métricas.
    Mostrar-Titulo -Titulo 'DETALLE DE MÉTRICAS' -Ancho 70
    Mostrar-Etiqueta -Etiqueta 'Uso de CPU' -Valor ("{0}%" -f $cpu) -ColorValor $(if ($cpu -gt 85) { 'Amarillo' } else { 'Blanco' })
    Mostrar-Etiqueta -Etiqueta 'Uso de memoria' -Valor ("{0}%" -f $mem.Porcentaje) -ColorValor $(if ($mem.Porcentaje -gt 85) { 'Amarillo' } else { 'Blanco' })
    foreach ($d in $discos) {
        $etiqueta = "Disco {0}" -f $d.Letra
        $valor = "{0} GB libres de {1} GB ({2}%)" -f $d.Libre, $d.Total, $d.Porcentaje
        $color = if ($d.Porcentaje -lt 10) { 'Rojo' } elseif ($d.Porcentaje -lt 20) { 'Amarillo' } else { 'Blanco' }
        Mostrar-Etiqueta -Etiqueta $etiqueta -Valor $valor -ColorValor $color
    }
    Mostrar-Etiqueta -Etiqueta 'Estado SMART' -Valor $smart -ColorValor $(if ($smart -eq 'Correcto') { 'Verde' } elseif ($smart -eq 'Degradado') { 'Rojo' } else { 'Gris' })
    Mostrar-Etiqueta -Etiqueta 'Defender tiempo real' -Valor $(if ($defender.ProteccionTiempoReal) { 'Activo' } else { 'Inactivo' }) -ColorValor $(if ($defender.ProteccionTiempoReal) { 'Verde' } else { 'Rojo' })
    Mostrar-Etiqueta -Etiqueta 'Definiciones antivirus' -Valor $(if ($defender.DefinicionesActualizadas) { 'Actualizadas' } else { 'Pendientes' }) -ColorValor $(if ($defender.DefinicionesActualizadas) { 'Verde' } else { 'Amarillo' })
    Mostrar-Etiqueta -Etiqueta 'Firewall (privado)' -Valor $(if ($firewall.PerfilPrivado) { 'Activo' } else { 'Inactivo' }) -ColorValor $(if ($firewall.PerfilPrivado) { 'Verde' } else { 'Rojo' })
    Mostrar-Etiqueta -Etiqueta 'Firewall (público)' -Valor $(if ($firewall.PerfilPublico) { 'Activo' } else { 'Inactivo' }) -ColorValor $(if ($firewall.PerfilPublico) { 'Verde' } else { 'Rojo' })
    Mostrar-Etiqueta -Etiqueta 'Servicios parados' -Valor $serviciosParados.Count -ColorValor $(if ($serviciosParados.Count -gt 0) { 'Amarillo' } else { 'Verde' })
    Mostrar-Etiqueta -Etiqueta 'Programas de inicio' -Valor $programasInicio.Count -ColorValor $(if ($programasInicio.Count -gt 10) { 'Amarillo' } else { 'Blanco' })
    Mostrar-Etiqueta -Etiqueta 'Actualizaciones pendientes' -Valor $actualizaciones -ColorValor $(if ($actualizaciones -gt 0) { 'Amarillo' } else { 'Verde' })
    Mostrar-Separador -Ancho 70 -Color Gris

    # Generación de recomendaciones.
    Mostrar-Titulo -Titulo 'RECOMENDACIONES' -Ancho 70
    $recomendaciones = @()
    foreach ($d in $discos) {
        if ($d.Porcentaje -lt 10) {
            $recomendaciones += "Liberar espacio en el disco {0} (queda menos del 10% libre)." -f $d.Letra
        }
    }
    if (-not $defender.ProteccionTiempoReal) {
        $recomendaciones += 'Activar la protección en tiempo real de Windows Defender.'
    }
    if (-not $defender.DefinicionesActualizadas) {
        $recomendaciones += 'Actualizar las definiciones de virus de Windows Defender.'
    }
    if (-not $firewall.PerfilPrivado -or -not $firewall.PerfilPublico) {
        $recomendaciones += 'Activar el firewall de Windows en todos los perfiles.'
    }
    if ($serviciosParados.Count -gt 0) {
        $recomendaciones += "Revisar {0} servicio(s) automático(s) que no se están ejecutando." -f $serviciosParados.Count
    }
    if ($programasInicio.Count -gt 10) {
        $recomendaciones += 'Reducir el número de programas que se ejecutan al inicio.'
    }
    if ($actualizaciones -gt 0) {
        $recomendaciones += 'Instalar las actualizaciones pendientes de Windows.'
    }
    if ($smart -eq 'Degradado') {
        $recomendaciones += 'Realizar copia de seguridad: se detectó un disco con estado SMART degradado.'
    }
    if ($cpu -gt 85) {
        $recomendaciones += 'Identificar procesos con alto consumo de CPU.'
    }
    if ($mem.Porcentaje -gt 85) {
        $recomendaciones += 'Identificar procesos con alto consumo de memoria.'
    }

    if ($recomendaciones.Count -eq 0) {
        Mostrar-Correcto -Mensaje 'No se detectaron recomendaciones. El sistema está en buen estado.'
    }
    else {
        Escribir-Color -Texto "Se detectaron $($recomendaciones.Count) recomendacion(es):" -Color Amarillo
        Escribir-Color -Texto '' -Color Gris
        foreach ($rec in $recomendaciones) {
            Escribir-Color -Texto "  * $rec" -Color Amarillo
        }
    }
    Mostrar-Separador -Ancho 70 -Color Gris

    Escribir-Registro -Mensaje "Análisis completado. Puntuación: $($puntuacion.Puntuacion)/100 ($($puntuacion.EstadoTexto))" -Nivel INFO
    Escribir-Color -Texto '' -Color Gris
    Esperar-Tecla
}

# Exportación pública del módulo.
Export-ModuleMember -Function Obtener-UsoCPU, Obtener-UsoMemoria, Obtener-EstadoDiscos, `
    Obtener-EstadoDefender, Obtener-EstadoFirewall, Obtener-ServiciosParados, Obtener-ProgramasInicio, `
    Obtener-ActualizacionesPendientes, Obtener-EstadoSMART, Obtener-PuntuacionSalud, Invoke-Salud
