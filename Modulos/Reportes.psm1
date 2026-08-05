<#
.SYNOPSIS
    Módulo de Reportes HTML de SYSCLIPSE.
.DESCRIPTION
    Genera un reporte profesional en HTML con el estado completo del
    sistema: información del equipo, puntuación de salud, métricas de
    rendimiento, seguridad, red y recomendaciones. El diseño del reporte
    utiliza una estética moderna y profesional.
.NOTES
    Versión : 1.1.0
    Autor   : SYSCLIPSE
#>

<#
.SYNOPSIS
    Genera la lista de recomendaciones basadas en el estado del sistema.
#>
function Generar-Recomendaciones {
    [CmdletBinding()]
    [OutputType([array])]
    param ()
    $recomendaciones = @()

    $cpu = Obtener-UsoCPU
    $mem = Obtener-UsoMemoria
    $discos = Obtener-EstadoDiscos
    $defender = Obtener-EstadoDefender
    $firewall = Obtener-EstadoFirewall
    $serviciosParados = Obtener-ServiciosParados
    $programasInicio = Obtener-ProgramasInicio
    $actualizaciones = Obtener-ActualizacionesPendientes
    $smart = Obtener-EstadoSMART
    $uac = Obtener-EstadoUAC

    foreach ($d in $discos) {
        if ($d.Porcentaje -lt 10) {
            $recomendaciones += "Liberar espacio en el disco $($d.Letra) (queda menos del 10% libre)."
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
    if (-not $uac.Habilitado) {
        $recomendaciones += 'Habilitar el Control de Cuentas de Usuario (UAC).'
    }
    if ($serviciosParados.Count -gt 0) {
        $recomendaciones += "Revisar $($serviciosParados.Count) servicio(s) automático(s) que no se están ejecutando."
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

    return $recomendaciones
}

<#
.SYNOPSIS
    Genera el contenido HTML del reporte.
#>
function Generar-ContenidoHTML {
    [CmdletBinding()]
    [OutputType([string])]
    param ()
    $info = Obtener-InfoSistema
    $puntuacion = Obtener-PuntuacionSalud
    $cpu = Obtener-UsoCPU
    $mem = Obtener-UsoMemoria
    $discos = Obtener-EstadoDiscos
    $defender = Obtener-EstadoDefender
    $firewall = Obtener-EstadoFirewall
    $uac = Obtener-EstadoUAC
    $bitlocker = Obtener-EstadoBitLocker
    $adaptadores = Obtener-AdaptadoresRed
    $conectividad = Probar-Conectividad
    $dns = Obtener-ServidoresDNS
    $recomendaciones = Generar-Recomendaciones
    $fecha = Obtener-FechaFormateada

    $colorEstado = switch ($puntuacion.EstadoColor) {
        'Verde'    { '#22c55e' }
        'Amarillo' { '#eab308' }
        'Rojo'     { '#ef4444' }
        default    { '#3b82f6' }
    }

    $html = @"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SYSCLIPSE - Reporte del Sistema</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, sans-serif;
            background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
            color: #e2e8f0;
            min-height: 100vh;
            padding: 40px 20px;
        }
        .contenedor { max-width: 900px; margin: 0 auto; }
        .encabezado {
            text-align: center;
            padding: 40px 30px;
            background: linear-gradient(135deg, #1e293b 0%, #334155 100%);
            border-radius: 16px;
            border: 1px solid #334155;
            margin-bottom: 30px;
        }
        .encabezado h1 {
            font-size: 2.5em;
            letter-spacing: 8px;
            color: #06b6d4;
            margin-bottom: 10px;
        }
        .encabezado .eslogan {
            color: #94a3b8;
            font-size: 1.1em;
        }
        .encabezado .version {
            color: #64748b;
            font-size: 0.9em;
            margin-top: 8px;
        }
        .tarjeta {
            background: #1e293b;
            border-radius: 12px;
            border: 1px solid #334155;
            padding: 30px;
            margin-bottom: 24px;
        }
        .tarjeta h2 {
            color: #06b6d4;
            font-size: 1.3em;
            margin-bottom: 20px;
            padding-bottom: 12px;
            border-bottom: 1px solid #334155;
        }
        .puntuacion-central {
            text-align: center;
            padding: 30px;
        }
        .puntuacion-numero {
            font-size: 4em;
            font-weight: bold;
            color: $colorEstado;
        }
        .puntuacion-numero span { color: #64748b; font-size: 0.5em; }
        .puntuacion-estado {
            font-size: 1.5em;
            color: $colorEstado;
            margin-top: 10px;
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
        .metrica {
            background: #0f172a;
            border-radius: 8px;
            padding: 20px;
            text-align: center;
            border: 1px solid #334155;
        }
        .metrica .titulo { color: #94a3b8; font-size: 0.85em; text-transform: uppercase; letter-spacing: 1px; }
        .metrica .valor { font-size: 2em; font-weight: bold; margin-top: 8px; color: #e2e8f0; }
        .tabla { width: 100%; border-collapse: collapse; margin-top: 16px; }
        .tabla th, .tabla td {
            padding: 12px 16px;
            text-align: left;
            border-bottom: 1px solid #334155;
        }
        .tabla th { color: #06b6d4; font-size: 0.85em; text-transform: uppercase; letter-spacing: 1px; }
        .tabla td { color: #cbd5e1; }
        .estado-verde { color: #22c55e; font-weight: bold; }
        .estado-amarillo { color: #eab308; font-weight: bold; }
        .estado-rojo { color: #ef4444; font-weight: bold; }
        .recomendacion {
            background: #0f172a;
            border-left: 4px solid #eab308;
            padding: 12px 16px;
            margin-bottom: 10px;
            border-radius: 4px;
            color: #e2e8f0;
        }
        .recomendacion.ok {
            border-left-color: #22c55e;
        }
        .pie {
            text-align: center;
            color: #64748b;
            padding: 20px;
            font-size: 0.85em;
        }
    </style>
</head>
<body>
    <div class="contenedor">
        <div class="encabezado">
            <h1>SYSCLIPSE</h1>
            <div class="eslogan">Suite Inteligente de Recuperación y Diagnóstico para Windows</div>
            <div class="version">Reporte generado el $fecha</div>
        </div>

        <div class="tarjeta">
            <h2>Puntuación de Salud</h2>
            <div class="puntuacion-central">
                <div class="puntuacion-numero">$($puntuacion.Puntuacion)<span>/100</span></div>
                <div class="puntuacion-estado">$($puntuacion.EstadoTexto)</div>
            </div>
            <div class="grid">
                <div class="metrica">
                    <div class="titulo">Rendimiento</div>
                    <div class="valor">$($puntuacion.Rendimiento)%</div>
                </div>
                <div class="metrica">
                    <div class="titulo">Seguridad</div>
                    <div class="valor">$($puntuacion.Seguridad)%</div>
                </div>
                <div class="metrica">
                    <div class="titulo">Estabilidad</div>
                    <div class="valor">$($puntuacion.Estabilidad)%</div>
                </div>
                <div class="metrica">
                    <div class="titulo">Mantenimiento</div>
                    <div class="valor">$($puntuacion.Mantenimiento)%</div>
                </div>
            </div>
        </div>

        <div class="tarjeta">
            <h2>Información del Equipo</h2>
            <table class="tabla">
                <tr><th>Equipo</th><td>$($info.NombreEquipo)</td></tr>
                <tr><th>Sistema operativo</th><td>$($info.SistemaOperativo)</td></tr>
                <tr><th>Versión</th><td>$($info.Version)</td></tr>
                <tr><th>Usuario</th><td>$($info.Usuario)</td></tr>
                <tr><th>Arquitectura</th><td>$($info.Arquitectura)</td></tr>
            </table>
        </div>

        <div class="tarjeta">
            <h2>Rendimiento</h2>
            <table class="tabla">
                <tr><th>Métrica</th><th>Valor</th></tr>
                <tr><td>Uso de CPU</td><td>$cpu%</td></tr>
                <tr><td>Uso de memoria</td><td>$($mem.Porcentaje)% ($($mem.Usado) GB / $($mem.Total) GB)</td></tr>
"@

    foreach ($d in $discos) {
        $html += "                <tr><td>Disco $($d.Letra)</td><td>$($d.Libre) GB libres de $($d.Total) GB ($($d.Porcentaje)%)</td></tr>`n"
    }

    $html += @"
            </table>
        </div>

        <div class="tarjeta">
            <h2>Seguridad</h2>
            <table class="tabla">
                <tr><th>Elemento</th><th>Estado</th></tr>
                <tr><td>Windows Defender</td><td class="$(if ($defender.Activo) { 'estado-verde' } else { 'estado-rojo' })">$(if ($defender.Activo) { 'Activo' } else { 'Inactivo' })</td></tr>
                <tr><td>Protección tiempo real</td><td class="$(if ($defender.ProteccionTiempoReal) { 'estado-verde' } else { 'estado-rojo' })">$(if ($defender.ProteccionTiempoReal) { 'Activa' } else { 'Inactiva' })</td></tr>
                <tr><td>Definiciones</td><td class="$(if ($defender.DefinicionesActualizadas) { 'estado-verde' } else { 'estado-amarillo' })">$(if ($defender.DefinicionesActualizadas) { 'Actualizadas' } else { 'Pendientes' })</td></tr>
                <tr><td>Firewall privado</td><td class="$(if ($firewall.PerfilPrivado) { 'estado-verde' } else { 'estado-rojo' })">$(if ($firewall.PerfilPrivado) { 'Activo' } else { 'Inactivo' })</td></tr>
                <tr><td>Firewall público</td><td class="$(if ($firewall.PerfilPublico) { 'estado-verde' } else { 'estado-rojo' })">$(if ($firewall.PerfilPublico) { 'Activo' } else { 'Inactivo' })</td></tr>
                <tr><td>UAC</td><td class="$(if ($uac.Habilitado) { 'estado-verde' } else { 'estado-rojo' })">$(if ($uac.Habilitado) { 'Habilitado' } else { 'Deshabilitado' })</td></tr>
"@

    if ($bitlocker.Count -gt 0) {
        foreach ($b in $bitlocker) {
            $clase = if ($b.Proteccion -eq 'On' -and $b.Cifrado -eq 100) { 'estado-verde' } elseif ($b.Cifrado -gt 0) { 'estado-amarillo' } else { 'estado-rojo' }
            $html += "                <tr><td>BitLocker $($b.Unidad)</td><td class=`"$clase`">$($b.Cifrado)% ($($b.Estado))</td></tr>`n"
        }
    }

    $html += @"
            </table>
        </div>

        <div class="tarjeta">
            <h2>Red</h2>
            <table class="tabla">
                <tr><th>Elemento</th><th>Valor</th></tr>
                <tr><td>Conectividad</td><td class="$(if ($conectividad.TieneInternet) { 'estado-verde' } else { 'estado-rojo' })">$(if ($conectividad.TieneInternet) { 'Disponible' } else { 'No disponible' })</td></tr>
                <tr><td>Latencia (8.8.8.8)</td><td>$(if ($conectividad.TieneInternet) { "$($conectividad.LatenciaMs) ms" } else { 'N/D' })</td></tr>
"@

    foreach ($a in $adaptadores) {
        $html += "                <tr><td>Adaptador $($a.Name)</td><td>$($a.LinkSpeed)</td></tr>`n"
    }

    foreach ($d in $dns) {
        $servidores = $d.ServerAddresses -join ', '
        $html += "                <tr><td>DNS $($d.InterfaceAlias)</td><td>$servidores</td></tr>`n"
    }

    $html += @"
            </table>
        </div>

        <div class="tarjeta">
            <h2>Recomendaciones</h2>
"@

    if ($recomendaciones.Count -eq 0) {
        $html += "            <div class=`"recomendacion ok`">No se detectaron recomendaciones. El sistema está en buen estado.</div>`n"
    }
    else {
        foreach ($rec in $recomendaciones) {
            $html += "            <div class=`"recomendacion`">$rec</div>`n"
        }
    }

    $html += @"
        </div>

        <div class="pie">
            Generado por SYSCLIPSE v1.1.0 - Suite Inteligente de Recuperación y Diagnóstico para Windows
        </div>
    </div>
</body>
</html>
"@

    return $html
}

<#
.SYNOPSIS
    Punto de entrada del módulo de Reportes.
#>
function Invoke-Reportes {
    [CmdletBinding()]
    param ()
    Preparar-Consola
    Mostrar-Titulo -Titulo 'GENERAR REPORTE HTML' -Ancho 70
    Escribir-Color -Texto 'Generando reporte profesional...' -Color Azul
    Escribir-Color -Texto '' -Color Gris

    $html = Generar-ContenidoHTML
    $carpetaReportes = Join-Path $Global:SysClipseRutaRaiz 'Reportes'
    Asegurar-Carpeta -Ruta $carpetaReportes
    $fechaArchivo = Get-Date -Format 'yyyy-MM-dd_HHmmss'
    $nombreArchivo = "Reporte_SYSCLIPSE_$fechaArchivo.html"
    $rutaReporte = Join-Path $carpetaReportes $nombreArchivo

    try {
        $html | Out-File -FilePath $rutaReporte -Encoding UTF8
        Mostrar-Correcto -Mensaje "Reporte generado: $nombreArchivo"
        Escribir-Registro -Mensaje "Reporte HTML generado: $rutaReporte" -Nivel OK
        Escribir-Color -Texto '' -Color Gris
        Escribir-Color -Texto "Ubicación: $rutaReporte" -Color Azul
        if (Confirmar-Accion -Pregunta '¿Desea abrir el reporte en el navegador?') {
            Start-Process -FilePath $rutaReporte
        }
    }
    catch {
        Mostrar-Error -Mensaje 'No se pudo generar el reporte.'
        Escribir-Registro -Mensaje "Error al generar reporte: $($_.Exception.Message)" -Nivel ERROR
    }
    Esperar-Tecla
}

Export-ModuleMember -Function Generar-Recomendaciones, Generar-ContenidoHTML, Invoke-Reportes
