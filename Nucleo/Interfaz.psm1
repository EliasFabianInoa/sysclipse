<#
.SYNOPSIS
    Núcleo de Interfaz de SYSCLIPSE.
.DESCRIPTION
    Proporciona el sistema de colores, banner, cajas, separadores y mensajes
    uniformes que toda la suite reutiliza para mantener una presentación
    profesional y consistente en consola.
.NOTES
    Versión : 1.1.0
    Autor   : SYSCLIPSE
#>

# ============================================================================
# Paleta de colores oficial de SYSCLIPSE
# ============================================================================
# Azul   -> Información
# Verde  -> Correcto
# Amarillo-> Advertencias
# Rojo   -> Errores
# Blanco -> Texto principal
# Cian   -> Títulos y banner
# ============================================================================

# Definición de alias de colores reutilizables en toda la suite.
$Global:SysClipseColores = @{
    Azul     = 'DarkCyan'
    Verde    = 'Green'
    Amarillo = 'Yellow'
    Rojo     = 'Red'
    Blanco   = 'White'
    Cian     = 'Cyan'
    Gris     = 'DarkGray'
    Oscuro   = 'Black'
}

<#
.SYNOPSIS
    Devuelve el nombre del color normalizado de SYSCLIPSE.
#>
function Obtener-Color {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Azul', 'Verde', 'Amarillo', 'Rojo', 'Blanco', 'Cian', 'Gris', 'Oscuro')]
        [string]$Nombre
    )
    return $Global:SysClipseColores[$Nombre]
}

<#
.SYNOPSIS
    Escribe una línea de texto con el color indicado, sin salto de línea final opcional.
#>
function Escribir-Color {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Texto,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Azul', 'Verde', 'Amarillo', 'Rojo', 'Blanco', 'Cian', 'Gris', 'Oscuro')]
        [string]$Color,

        [switch]$SinSalto
    )
    $colorSistema = Obtener-Color -Nombre $Color
    if ($SinSalto) {
        Write-Host -NoNewline -ForegroundColor $colorSistema $Texto
    }
    else {
        Write-Host -ForegroundColor $colorSistema $Texto
    }
}

<#
.SYNOPSIS
    Imprime una línea separadora del ancho de la consola.
#>
function Mostrar-Separador {
    [CmdletBinding()]
    param (
        [string]$Caracter = '-',
        [int]$Ancho = 70,
        [ValidateSet('Azul', 'Verde', 'Amarillo', 'Rojo', 'Blanco', 'Cian', 'Gris', 'Oscuro')]
        [string]$Color = 'Gris'
    )
    $linea = $Caracter * $Ancho
    Escribir-Color -Texto $linea -Color $Color
}

<#
.SYNOPSIS
    Imprime una línea doble de título usada como borde superior/inferior.
#>
function Mostrar-Borde {
    [CmdletBinding()]
    param (
        [int]$Ancho = 70,
        [ValidateSet('Azul', 'Verde', 'Amarillo', 'Rojo', 'Blanco', 'Cian', 'Gris', 'Oscuro')]
        [string]$Color = 'Cian'
    )
    $linea = '=' * $Ancho
    Escribir-Color -Texto $linea -Color $Color
}

<#
.SYNOPSIS
    Dibuja una caja centrada con un título.
.DESCRIPTION
    Utilidad para encabezados de sección dentro de los módulos.
#>
function Mostrar-Titulo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Titulo,

        [int]$Ancho = 70
    )
    Mostrar-Borde -Ancho $Ancho -Color Cian
    $espacios = [math]::Max(0, [int](($Ancho - $Titulo.Length) / 2))
    $centro = (' ' * $espacios) + $Titulo
    Escribir-Color -Texto $centro -Color Cian
    Mostrar-Borde -Ancho $Ancho -Color Cian
}

<#
.SYNOPSIS
    Muestra el banner oficial de SYSCLIPSE con el logo ASCII.
#>
function Mostrar-Banner {
    [CmdletBinding()]
    param ()
    $rutaLogo = Join-Path $Global:SysClipseRutaRecursos 'Logo.txt'
    $rutaBanner = Join-Path $Global:SysClipseRutaRecursos 'Banner.txt'

    Mostrar-Borde -Ancho 75 -Color Cian
    if (Test-Path $rutaLogo) {
        Get-Content -Path $rutaLogo -Raw -Encoding UTF8 | ForEach-Object {
            Escribir-Color -Texto $_ -Color Cian
        }
    }
    if (Test-Path $rutaBanner) {
        Get-Content -Path $rutaBanner -Raw -Encoding UTF8 | ForEach-Object {
            Escribir-Color -Texto $_ -Color Azul
        }
    }
    Mostrar-Borde -Ancho 75 -Color Cian
}

<#
.SYNOPSIS
    Muestra un mensaje informativo con prefijo [INFO].
#>
function Mostrar-Info {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Mensaje
    )
    Escribir-Color -Texto '[INFO] ' -Color Azul -SinSalto
    Escribir-Color -Texto $Mensaje -Color Blanco
}

<#
.SYNOPSIS
    Muestra un mensaje de correcto con prefijo [OK].
#>
function Mostrar-Correcto {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Mensaje
    )
    Escribir-Color -Texto '[OK] ' -Color Verde -SinSalto
    Escribir-Color -Texto $Mensaje -Color Blanco
}

<#
.SYNOPSIS
    Muestra una advertencia con prefijo [AVISO].
#>
function Mostrar-Aviso {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Mensaje
    )
    Escribir-Color -Texto '[AVISO] ' -Color Amarillo -SinSalto
    Escribir-Color -Texto $Mensaje -Color Amarillo
}

<#
.SYNOPSIS
    Muestra un error con prefijo [ERROR].
#>
function Mostrar-Error {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Mensaje
    )
    Escribir-Color -Texto '[ERROR] ' -Color Rojo -SinSalto
    Escribir-Color -Texto $Mensaje -Color Rojo
}

<#
.SYNOPSIS
    Imprime una etiqueta y su valor alineados, estilo panel de información.
.DESCRIPTION
    Ejemplo:  Nombre del equipo    DESKTOP-ABC123
#>
function Mostrar-Etiqueta {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Etiqueta,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Valor,

        [ValidateSet('Azul', 'Verde', 'Amarillo', 'Rojo', 'Blanco', 'Cian', 'Gris', 'Oscuro')]
        [string]$ColorValor = 'Blanco'
    )
    $etiquetaFormateada = (' {0,-28}' -f $Etiqueta)
    Escribir-Color -Texto $etiquetaFormateada -Color Gris -SinSalto
    Escribir-Color -Texto $Valor -Color $ColorValor
}

<#
.SYNOPSIS
    Limpia la pantalla y prepara la consola con codificación UTF-8.
#>
function Preparar-Consola {
    [CmdletBinding()]
    param ()
    Clear-Host
    try {
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        [Console]::InputEncoding = [System.Text.Encoding]::UTF8
        $Host.UI.RawUI.WindowTitle = 'SYSCLIPSE - Suite Inteligente de Recuperación y Diagnóstico'
        # Alinea la página de códigos del terminal con UTF-8, necesario en consolas
        # heredadas (conhost / Windows PowerShell 5.1) para evitar caracteres corruptos.
        chcp 65001 > $null
    }
    catch {
        # En entornos sin UI interactiva se omite silenciosamente.
    }
}

<#
.SYNOPSIS
    Pausa la ejecución hasta que el usuario presione una tecla.
#>
function Esperar-Tecla {
    [CmdletBinding()]
    param (
        [string]$Mensaje = 'Presione una tecla para continuar...'
    )
    Escribir-Color -Texto '' -Color Gris
    Escribir-Color -Texto $Mensaje -Color Gris -SinSalto
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    Escribir-Color -Texto '' -Color Gris
}

<#
.SYNOPSIS
    Solicita confirmación Sí/No al usuario.
.OUTPUTS
    $true si el usuario responde Sí, $false en caso contrario.
#>
function Confirmar-Accion {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Pregunta
    )
    Escribir-Color -Texto '' -Color Gris
    Escribir-Color -Texto "[?] $Pregunta (S/N): " -Color Amarillo -SinSalto
    $respuesta = Read-Host
    return ($respuesta.Trim().ToUpper() -eq 'S')
}

<#
.SYNOPSIS
    Muestra una barra de progreso simple basada en pasos.
.DESCRIPTION
    Cada llamada avanza el contador interno para simular progreso.
#>
function Mostrar-Progreso {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Tarea,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 100)]
        [int]$Porcentaje
    )
    $barraAncho = 30
    $completado = [int](($Porcentaje / 100) * $barraAncho)
    $restante = $barraAncho - $completado
    $barra = ('#' * $completado) + ('-' * $restante)
    Escribir-Color -Texto ("`r{0} [{1}] {2}%" -f $Tarea, $barra, $Porcentaje) -Color Cian -SinSalto
    if ($Porcentaje -ge 100) {
        Escribir-Color -Texto '' -Color Cian
    }
}

# Exportación pública del módulo.
Export-ModuleMember -Function Obtener-Color, Escribir-Color, Mostrar-Separador, `
    Mostrar-Borde, Mostrar-Titulo, Mostrar-Banner, Mostrar-Info, Mostrar-Correcto, `
    Mostrar-Aviso, Mostrar-Error, Mostrar-Etiqueta, Preparar-Consola, Esperar-Tecla, `
    Confirmar-Accion, Mostrar-Progreso
