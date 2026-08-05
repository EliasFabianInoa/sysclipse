<#
.SYNOPSIS
    Módulo de Rendimiento de SYSCLIPSE.
.DESCRIPTION
    Analiza el rendimiento del sistema: CPU, memoria, discos, procesos
    consumidores y tiempos de arranque. Genera recomendaciones para
    optimizar el sistema sin ejecutar acciones peligrosas.
.NOTES
    Versión : 1.1.0
    Autor   : SYSCLIPSE
#>

<#
.SYNOPSIS
    Obtiene los procesos con mayor consumo de CPU.
#>
function Obtener-ProcesosCPU {
    [CmdletBinding()]
    [OutputType([array])]
    param (
        [int]$Top = 5
    )
    try {
        return Get-Process -ErrorAction Stop | Sort-Object CPU -Descending | Select-Object -First $Top Name, @{N = 'CPU'; E = { [math]::Round($_.CPU, 1) } }
    }
    catch { return @() }
}

<#
.SYNOPSIS
    Obtiene los procesos con mayor consumo de memoria.
#>
function Obtener-ProcesosMemoria {
    [CmdletBinding()]
    [OutputType([array])]
    param (
        [int]$Top = 5
    )
    try {
        return Get-Process -ErrorAction Stop | Sort-Object WorkingSet -Descending | Select-Object -First $Top Name, @{N = 'MemoriaMB'; E = { [math]::Round($_.WorkingSet / 1MB, 1) } }
    }
    catch { return @() }
}

<#
.SYNOPSIS
    Obtiene el tiempo de arranque del sistema.
#>
function Obtener-TiempoArranque {
    [CmdletBinding()]
    [OutputType([string])]
    param ()
    try {
        $so = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $tiempoArranque = $so.LastBootUpTime
        $tiempoActividad = (Get-Date) - $tiempoArranque
        $dias = $tiempoActividad.Days
        $horas = $tiempoActividad.Hours
        $minutos = $tiempoActividad.Minutes
        return "{0}d {1}h {2}m" -f $dias, $horas, $minutos
    }
    catch { return 'No disponible' }
}

<#
.SYNOPSIS
    Punto de entrada del módulo de Rendimiento.
#>
function Invoke-Rendimiento {
    [CmdletBinding()]
    param ()
    Preparar-Consola
    Mostrar-Titulo -Titulo 'ANALIZADOR DE RENDIMIENTO' -Ancho 70
    Escribir-Color -Texto 'Recopilando métricas de rendimiento...' -Color Azul
    Escribir-Color -Texto '' -Color Gris

    $cpu = Obtener-UsoCPU
    $mem = Obtener-UsoMemoria
    $tiempoArranque = Obtener-TiempoArranque
    $procCPU = Obtener-ProcesosCPU
    $procMem = Obtener-ProcesosMemoria

    Mostrar-Titulo -Titulo 'MÉTRICAS DE RENDIMIENTO' -Ancho 70
    Mostrar-Etiqueta -Etiqueta 'Uso de CPU' -Valor ("{0}%" -f $cpu) -ColorValor $(if ($cpu -gt 85) { 'Rojo' } elseif ($cpu -gt 60) { 'Amarillo' } else { 'Verde' })
    Mostrar-Etiqueta -Etiqueta 'Uso de memoria' -Valor ("{0}% ({1} GB / {2} GB)" -f $mem.Porcentaje, $mem.Usado, $mem.Total) -ColorValor $(if ($mem.Porcentaje -gt 85) { 'Rojo' } elseif ($mem.Porcentaje -gt 60) { 'Amarillo' } else { 'Verde' })
    Mostrar-Etiqueta -Etiqueta 'Tiempo de actividad' -Valor $tiempoArranque -ColorValor Blanco
    Mostrar-Separador -Ancho 70 -Color Gris

    Mostrar-Titulo -Titulo 'PROCESOS CON MAYOR CPU' -Ancho 70
    if ($procCPU.Count -eq 0) {
        Mostrar-Aviso -Mensaje 'No se pudieron obtener los procesos.'
    }
    else {
        foreach ($p in $procCPU) {
            Mostrar-Etiqueta -Etiqueta $p.Name -Valor ("{0}s" -f $p.CPU) -ColorValor Blanco
        }
    }
    Mostrar-Separador -Ancho 70 -Color Gris

    Mostrar-Titulo -Titulo 'PROCESOS CON MAYOR MEMORIA' -Ancho 70
    if ($procMem.Count -eq 0) {
        Mostrar-Aviso -Mensaje 'No se pudieron obtener los procesos.'
    }
    else {
        foreach ($p in $procMem) {
            Mostrar-Etiqueta -Etiqueta $p.Name -Valor ("{0} MB" -f $p.MemoriaMB) -ColorValor Blanco
        }
    }
    Mostrar-Separador -Ancho 70 -Color Gris

    Escribir-Registro -Mensaje 'Análisis de rendimiento completado.' -Nivel INFO
    Esperar-Tecla
}

Export-ModuleMember -Function Obtener-ProcesosCPU, Obtener-ProcesosMemoria, Obtener-TiempoArranque, Invoke-Rendimiento
