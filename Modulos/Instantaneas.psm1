<#
.SYNOPSIS
    Módulo de Instantáneas de SYSCLIPSE.
.DESCRIPTION
    Permite capturar el estado del sistema en un momento dado, listar
    las instantáneas guardadas y comparar dos instantáneas para detectar
    cambios en la puntuación de salud, servicios, programas de inicio
    y espacio en disco.
.NOTES
    Versión : 1.1.0
    Autor   : SYSCLIPSE
#>

<#
.SYNOPSIS
    Captura una instantánea del estado actual del sistema.
.OUTPUTS
    Hashtable con la fecha y las métricas del sistema.
#>
function Nueva-Instantanea {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param ()
    $instantanea = @{
        Fecha           = (Get-Date).ToString('o')
        Puntuacion      = (Obtener-PuntuacionSalud).Puntuacion
        Servicios       = (Obtener-ServiciosParados).Count
        ProgramasInicio = (Obtener-ProgramasInicio).Count
        Discos          = @()
    }
    foreach ($d in (Obtener-EstadoDiscos)) {
        $instantanea.Discos += @{
            Letra      = $d.Letra
            Libre      = $d.Libre
            Porcentaje = $d.Porcentaje
        }
    }
    return $instantanea
}

<#
.SYNOPSIS
    Guarda una instantánea en disco como archivo JSON.
#>
function Guardar-Instantanea {
    [CmdletBinding()]
    [OutputType([string])]
    param ()
    $carpeta = Join-Path $Global:SysClipseRutaRaiz 'Reportes/Instantaneas'
    Asegurar-Carpeta -Ruta $carpeta
    $instantanea = Nueva-Instantanea
    $fechaArchivo = Get-Date -Format 'yyyy-MM-dd_HHmmss'
    $ruta = Join-Path $carpeta "Instantanea_$fechaArchivo.json"
    $instantanea | ConvertTo-Json -Depth 5 | Out-File -FilePath $ruta -Encoding UTF8
    return $ruta
}

<#
.SYNOPSIS
    Lista las instantáneas guardadas.
#>
function Listar-Instantaneas {
    [CmdletBinding()]
    [OutputType([array])]
    param ()
    $carpeta = Join-Path $Global:SysClipseRutaRaiz 'Reportes/Instantaneas'
    if (-not (Test-Path $carpeta)) { return @() }
    return Get-ChildItem -Path $carpeta -Filter '*.json' -File |
        Sort-Object LastWriteTime -Descending |
        Select-Object Name, LastWriteTime, FullName
}

<#
.SYNOPSIS
    Carga una instantánea desde un archivo JSON.
#>
function Cargar-Instantanea {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Ruta
    )
    try {
        $json = Get-Content -Path $Ruta -Raw -Encoding UTF8 | ConvertFrom-Json
        $tabla = @{
            Fecha           = $json.Fecha
            Puntuacion      = [int]$json.Puntuacion
            Servicios       = [int]$json.Servicios
            ProgramasInicio = [int]$json.ProgramasInicio
            Discos          = @()
        }
        foreach ($d in $json.Discos) {
            $tabla.Discos += @{
                Letra      = $d.Letra
                Libre      = [double]$d.Libre
                Porcentaje = [int]$d.Porcentaje
            }
        }
        return $tabla
    }
    catch {
        return $null
    }
}

<#
.SYNOPSIS
    Compara dos instantáneas y muestra las diferencias.
.DESCRIPTION
    Muestra los cambios en puntuación, servicios parados, programas de
    inicio y espacio libre en cada disco entre dos instantáneas.
#>
function Comparar-Instantaneas {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Antigua,

        [Parameter(Mandatory = $true)]
        [hashtable]$Nueva
    )
    Mostrar-Titulo -Titulo 'COMPARACIÓN DE INSTANTÁNEAS' -Ancho 70

    $fechaAntigua = [datetime]::Parse($Antigua.Fecha).ToString('yyyy-MM-dd HH:mm')
    $fechaNueva = [datetime]::Parse($Nueva.Fecha).ToString('yyyy-MM-dd HH:mm')

    Mostrar-Etiqueta -Etiqueta 'Instantánea antigua' -Valor $fechaAntigua -ColorValor Gris
    Mostrar-Etiqueta -Etiqueta 'Instantánea nueva' -Valor $fechaNueva -ColorValor Gris
    Mostrar-Separador -Ancho 70 -Color Gris

    # Diferencia de puntuación.
    $diffPuntuacion = $Nueva.Puntuacion - $Antigua.Puntuacion
    $simbolo = if ($diffPuntuacion -gt 0) { '+' } elseif ($diffPuntuacion -lt 0) { '' } else { '=' }
    $colorPuntuacion = if ($diffPuntuacion -gt 0) { 'Verde' } elseif ($diffPuntuacion -lt 0) { 'Rojo' } else { 'Blanco' }
    Mostrar-Etiqueta -Etiqueta 'Puntuación' -Valor ("$($Antigua.Puntuacion) -> $($Nueva.Puntuacion) ($simbolo$diffPuntuacion)") -ColorValor $colorPuntuacion

    # Diferencia de servicios parados.
    $diffServicios = $Nueva.Servicios - $Antigua.Servicios
    $simboloServicios = if ($diffServicios -gt 0) { '+' } elseif ($diffServicios -lt 0) { '' } else { '=' }
    $colorServicios = if ($diffServicios -lt 0) { 'Verde' } elseif ($diffServicios -gt 0) { 'Rojo' } else { 'Blanco' }
    Mostrar-Etiqueta -Etiqueta 'Servicios parados' -Valor ("$($Antigua.Servicios) -> $($Nueva.Servicios) ($simboloServicios$diffServicios)") -ColorValor $colorServicios

    # Diferencia de programas de inicio.
    $diffProgramas = $Nueva.ProgramasInicio - $Antigua.ProgramasInicio
    $simboloProgramas = if ($diffProgramas -gt 0) { '+' } elseif ($diffProgramas -lt 0) { '' } else { '=' }
    $colorProgramas = if ($diffProgramas -lt 0) { 'Verde' } elseif ($diffProgramas -gt 0) { 'Amarillo' } else { 'Blanco' }
    Mostrar-Etiqueta -Etiqueta 'Programas de inicio' -Valor ("$($Antigua.ProgramasInicio) -> $($Nueva.ProgramasInicio) ($simboloProgramas$diffProgramas)") -ColorValor $colorProgramas

    Mostrar-Separador -Ancho 70 -Color Gris

    # Comparación de discos.
    Escribir-Color -Texto '  Espacio libre por disco:' -Color Cian
    foreach ($dAntigua in $Antigua.Discos) {
        $dNueva = $Nueva.Discos | Where-Object { $_.Letra -eq $dAntigua.Letra } | Select-Object -First 1
        if ($dNueva) {
            $diffLibre = [math]::Round($dNueva.Libre - $dAntigua.Libre, 2)
            $simboloDisco = if ($diffLibre -gt 0) { '+' } elseif ($diffLibre -lt 0) { '' } else { '=' }
            $colorDisco = if ($diffLibre -gt 0) { 'Verde' } elseif ($diffLibre -lt 0) { 'Rojo' } else { 'Blanco' }
            $valor = "$($dAntigua.Libre) GB -> $($dNueva.Libre) GB ($simboloDisco$diffLibre GB)"
            Mostrar-Etiqueta -Etiqueta "  Disco $($dAntigua.Letra)" -Valor $valor -ColorValor $colorDisco
        }
    }
    Mostrar-Separador -Ancho 70 -Color Gris
}

<#
.SYNOPSIS
    Muestra el menú de selección de instantáneas para comparar.
#>
function Seleccionar-Comparacion {
    [CmdletBinding()]
    param ()
    $lista = Listar-Instantaneas
    if ($lista.Count -lt 2) {
        Mostrar-Aviso -Mensaje 'Se necesitan al menos dos instantáneas para comparar.'
        return
    }

    Escribir-Color -Texto 'Instantáneas disponibles:' -Color Cian
    Escribir-Color -Texto '' -Color Gris
    $i = 0
    foreach ($item in $lista) {
        $i++
        Escribir-Color -Texto ("  {0}. {1}  ({2})" -f $i, $item.Name, $item.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) -Color Blanco
    }
    Escribir-Color -Texto '' -Color Gris

    Escribir-Color -Texto 'Seleccione el número de la instantánea ANTIGUA: ' -Color Amarillo -SinSalto
    $opAntigua = Read-Host
    Escribir-Color -Texto 'Seleccione el número de la instantánea NUEVA: ' -Color Amarillo -SinSalto
    $opNueva = Read-Host

    $idxAntigua = 0
    $idxNueva = 0
    if (-not ([int]::TryParse($opAntigua.Trim(), [ref]$idxAntigua)) -or
        -not ([int]::TryParse($opNueva.Trim(), [ref]$idxNueva))) {
        Mostrar-Aviso -Mensaje 'Opción no válida.'
        return
    }
    if ($idxAntigua -lt 1 -or $idxAntigua -gt $lista.Count -or
        $idxNueva -lt 1 -or $idxNueva -gt $lista.Count) {
        Mostrar-Aviso -Mensaje 'Número fuera de rango.'
        return
    }
    if ($idxAntigua -eq $idxNueva) {
        Mostrar-Aviso -Mensaje 'Seleccione dos instantáneas diferentes.'
        return
    }

    $antigua = Cargar-Instantanea -Ruta $lista[$idxAntigua - 1].FullName
    $nueva = Cargar-Instantanea -Ruta $lista[$idxNueva - 1].FullName

    if ($null -eq $antigua -or $null -eq $nueva) {
        Mostrar-Error -Mensaje 'No se pudieron cargar las instantáneas.'
        return
    }

    Comparar-Instantaneas -Antigua $antigua -Nueva $nueva
    Escribir-Registro -Mensaje "Comparación entre $($lista[$idxAntigua - 1].Name) y $($lista[$idxNueva - 1].Name)" -Nivel INFO
}

<#
.SYNOPSIS
    Muestra los detalles de una instantánea seleccionada.
#>
function Mostrar-DetalleInstantanea {
    [CmdletBinding()]
    param ()
    $lista = Listar-Instantaneas
    if ($lista.Count -eq 0) {
        Mostrar-Aviso -Mensaje 'No hay instantáneas guardadas.'
        return
    }

    Escribir-Color -Texto 'Instantáneas disponibles:' -Color Cian
    Escribir-Color -Texto '' -Color Gris
    $i = 0
    foreach ($item in $lista) {
        $i++
        Escribir-Color -Texto ("  {0}. {1}  ({2})" -f $i, $item.Name, $item.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) -Color Blanco
    }
    Escribir-Color -Texto '' -Color Gris

    Escribir-Color -Texto 'Seleccione el número de la instantánea: ' -Color Amarillo -SinSalto
    $opcion = Read-Host
    $idx = 0
    if (-not ([int]::TryParse($opcion.Trim(), [ref]$idx)) -or $idx -lt 1 -or $idx -gt $lista.Count) {
        Mostrar-Aviso -Mensaje 'Opción no válida.'
        return
    }

    $datos = Cargar-Instantanea -Ruta $lista[$idx - 1].FullName
    if ($null -eq $datos) {
        Mostrar-Error -Mensaje 'No se pudo cargar la instantánea.'
        return
    }

    $fecha = [datetime]::Parse($datos.Fecha).ToString('yyyy-MM-dd HH:mm:ss')
    Mostrar-Titulo -Titulo 'DETALLE DE INSTANTÁNEA' -Ancho 70
    Mostrar-Etiqueta -Etiqueta 'Archivo' -Valor $lista[$idx - 1].Name -ColorValor Blanco
    Mostrar-Etiqueta -Etiqueta 'Fecha de captura' -Valor $fecha -ColorValor Blanco
    Mostrar-Etiqueta -Etiqueta 'Puntuación' -Valor "$($datos.Puntuacion)/100" -ColorValor $(if ($datos.Puntuacion -ge 75) { 'Verde' } elseif ($datos.Puntuacion -ge 60) { 'Amarillo' } else { 'Rojo' })
    Mostrar-Etiqueta -Etiqueta 'Servicios parados' -Valor $datos.Servicios -ColorValor Blanco
    Mostrar-Etiqueta -Etiqueta 'Programas de inicio' -Valor $datos.ProgramasInicio -ColorValor Blanco
    Mostrar-Separador -Ancho 70 -Color Gris
    Escribir-Color -Texto '  Discos:' -Color Cian
    foreach ($d in $datos.Discos) {
        $valor = "$($d.Libre) GB libres ($($d.Porcentaje)%)"
        $color = if ($d.Porcentaje -lt 10) { 'Rojo' } elseif ($d.Porcentaje -lt 20) { 'Amarillo' } else { 'Verde' }
        Mostrar-Etiqueta -Etiqueta "    Disco $($d.Letra)" -Valor $valor -ColorValor $color
    }
    Mostrar-Separador -Ancho 70 -Color Gris
}

<#
.SYNOPSIS
    Punto de entrada del módulo de Instantáneas.
#>
function Invoke-Instantaneas {
    [CmdletBinding()]
    param ()
    Preparar-Consola
    Mostrar-Titulo -Titulo 'INSTANTÁNEAS DEL SISTEMA' -Ancho 70
    Escribir-Color -Texto '  1. Capturar instantánea actual' -Color Blanco
    Escribir-Color -Texto '  2. Listar instantáneas guardadas' -Color Blanco
    Escribir-Color -Texto '  3. Ver detalle de una instantánea' -Color Blanco
    Escribir-Color -Texto '  4. Comparar dos instantáneas' -Color Blanco
    Escribir-Color -Texto '  0. Volver al menú principal' -Color Rojo
    Mostrar-Separador -Ancho 70 -Color Gris
    Escribir-Color -Texto 'Seleccione una opción: ' -Color Cian -SinSalto
    $opcion = Read-Host

    switch ($opcion.Trim()) {
        '1' {
            $ruta = Guardar-Instantanea
            Mostrar-Correcto -Mensaje "Instantánea guardada: $(Split-Path $ruta -Leaf)"
            Escribir-Registro -Mensaje "Instantánea capturada: $ruta" -Nivel OK
        }
        '2' {
            $lista = Listar-Instantaneas
            if ($lista.Count -eq 0) {
                Mostrar-Aviso -Mensaje 'No hay instantáneas guardadas.'
            }
            else {
                Mostrar-Separador -Ancho 70 -Color Gris
                foreach ($item in $lista) {
                    Mostrar-Etiqueta -Etiqueta $item.Name -Valor $item.LastWriteTime.ToString('yyyy-MM-dd HH:mm') -ColorValor Blanco
                }
            }
        }
        '3' { Mostrar-DetalleInstantanea }
        '4' { Seleccionar-Comparacion }
        '0' { return }
        default { Mostrar-Aviso -Mensaje 'Opción no válida.' }
    }
    Esperar-Tecla
}

Export-ModuleMember -Function Nueva-Instantanea, Guardar-Instantanea, Listar-Instantaneas, `
    Cargar-Instantanea, Comparar-Instantaneas, Seleccionar-Comparacion, `
    Mostrar-DetalleInstantanea, Invoke-Instantaneas
