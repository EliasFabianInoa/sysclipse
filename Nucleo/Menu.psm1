<#
.SYNOPSIS
    Menú principal de SYSCLIPSE.
.DESCRIPTION
    Define el menú navegable, la cabecera con información del sistema y la
    puntuación de salud, y el bucle principal de selección de opciones.
.NOTES
    Versión : 1.1.0
    Autor   : SYSCLIPSE
#>

<#
.SYNOPSIS
    Muestra la cabecera del menú con datos del equipo y puntuación de salud.
#>
function Mostrar-CabeceraMenu {
    [CmdletBinding()]
    param ()
    $info = Obtener-InfoSistema
    $puntuacion = Obtener-PuntuacionSalud
    $estado = $puntuacion.EstadoTexto

    Mostrar-Borde -Ancho 70 -Color Cian
    Mostrar-Etiqueta -Etiqueta 'Nombre del equipo' -Valor $info.NombreEquipo -ColorValor Blanco
    Mostrar-Etiqueta -Etiqueta 'Sistema operativo' -Valor $info.SistemaOperativo -ColorValor Blanco
    Mostrar-Etiqueta -Etiqueta 'Usuario' -Valor $info.Usuario -ColorValor Blanco
    Mostrar-Etiqueta -Etiqueta 'Estado general' -Valor $estado -ColorValor $puntuacion.EstadoColor
    Mostrar-Etiqueta -Etiqueta 'Puntuación de salud' -Valor ("{0}/100" -f $puntuacion.Puntuacion) -ColorValor $puntuacion.EstadoColor
    Mostrar-Separador -Ancho 70 -Color Gris
}

<#
.SYNOPSIS
    Muestra el menú principal con sus opciones.
#>
function Mostrar-OpcionesMenu {
    [CmdletBinding()]
    param ()
    $opciones = @(
        @{ Numero = '1'; Texto = 'Análisis completo' }
        @{ Numero = '2'; Texto = 'Centro de recuperación' }
        @{ Numero = '3'; Texto = 'Analizador de rendimiento' }
        @{ Numero = '4'; Texto = 'Auditoría de seguridad' }
        @{ Numero = '5'; Texto = 'Diagnóstico de red' }
        @{ Numero = '6'; Texto = 'Generar reporte HTML' }
        @{ Numero = '7'; Texto = 'Instantáneas del sistema' }
        @{ Numero = '8'; Texto = 'Configuración' }
        @{ Numero = '0'; Texto = 'Salir' }
    )
    foreach ($opcion in $opciones) {
        $linea = '  {0}. {1}' -f $opcion.Numero, $opcion.Texto
        if ($opcion.Numero -eq '0') {
            Escribir-Color -Texto $linea -Color Rojo
        }
        else {
            Escribir-Color -Texto $linea -Color Blanco
        }
    }
    Mostrar-Borde -Ancho 70 -Color Cian
}

<#
.SYNOPSIS
    Procesa la opción seleccionada por el usuario.
#>
function Procesar-Opcion {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Opcion
    )
    switch ($Opcion) {
        '1' { Invoke-AccionModulo -Modulo 'Salud'; return $true }
        '2' { Invoke-AccionModulo -Modulo 'Recuperacion'; return $true }
        '3' { Invoke-AccionModulo -Modulo 'Rendimiento'; return $true }
        '4' { Invoke-AccionModulo -Modulo 'Seguridad'; return $true }
        '5' { Invoke-AccionModulo -Modulo 'Red'; return $true }
        '6' { Invoke-AccionModulo -Modulo 'Reportes'; return $true }
        '7' { Invoke-AccionModulo -Modulo 'Instantaneas'; return $true }
        '8' { Mostrar-Configuracion; return $true }
        '0' { return $false }
        default {
            Mostrar-Aviso -Mensaje 'Opción no válida. Seleccione un número del menú.'
            Esperar-Tecla
            return $true
        }
    }
}

<#
.SYNOPSIS
    Muestra la pantalla de configuración.
#>
function Mostrar-Configuracion {
    [CmdletBinding()]
    param ()
    Mostrar-Titulo -Titulo 'CONFIGURACIÓN' -Ancho 70
    $config = $Global:SysClipseConfiguracion
    if ($config.Count -eq 0) {
        Mostrar-Aviso -Mensaje 'No se encontró el archivo de configuración.'
    }
    else {
        Mostrar-Etiqueta -Etiqueta 'Versión' -Valor $config.Version -ColorValor Blanco
        Mostrar-Etiqueta -Etiqueta 'Idioma' -Valor $config.Idioma -ColorValor Blanco
        Mostrar-Etiqueta -Etiqueta 'Nivel de registro' -Valor $config.NivelRegistro -ColorValor Blanco
        Mostrar-Etiqueta -Etiqueta 'Reportes automáticos' -Valor $config.ReportesAutomaticos -ColorValor Blanco
        Mostrar-Etiqueta -Etiqueta 'Confirmación acciones' -Valor $config.ConfirmarAcciones -ColorValor Blanco
    }
    Mostrar-Separador -Ancho 70 -Color Gris
    Esperar-Tecla
}

<#
.SYNOPSIS
    Bucle principal del menú de SYSCLIPSE.
#>
function Mostrar-MenuPrincipal {
    [CmdletBinding()]
    param ()
    $continuar = $true
    while ($continuar) {
        Preparar-Consola
        Mostrar-Banner
        Mostrar-CabeceraMenu
        Mostrar-OpcionesMenu
        Escribir-Color -Texto 'Seleccione una opción: ' -Color Cian -SinSalto
        $opcion = Read-Host
        $continuar = Procesar-Opcion -Opcion $opcion.Trim()
    }
}

# Exportación pública del módulo.
Export-ModuleMember -Function Mostrar-CabeceraMenu, Mostrar-OpcionesMenu, `
    Procesar-Opcion, Mostrar-Configuracion, Mostrar-MenuPrincipal
