<#
.SYNOPSIS
    Motor central de SYSCLIPSE.
.DESCRIPTION
    Orquesta la carga de módulos, el registro de módulos disponibles y el
    despacho de acciones solicitadas por el menú. Actúa como único punto de
    comunicación entre la interfaz y los módulos funcionales.
.NOTES
    Versión : 1.1.0
    Autor   : SYSCLIPSE
#>

# Registro en memoria de los módulos disponibles.
$Global:SysClipseModulos = @{}

<#
.SYNOPSIS
    Carga e importa todos los módulos .psm1 de la carpeta Modulos.
.DESCRIPTION
    Importa cada módulo y registra su nombre en el catálogo interno para
    que el motor pueda despachar acciones hacia él.
#>
function Cargar-Modulos {
    [CmdletBinding()]
    param ()
    $rutaModulos = Join-Path $Global:SysClipseRutaRaiz 'Modulos'
    if (-not (Test-Path $rutaModulos)) {
        return
    }
    $modulos = Get-ChildItem -Path $rutaModulos -Filter '*.psm1' -File
    foreach ($modulo in $modulos) {
        try {
            Import-Module -Name $modulo.FullName -Force -Global -ErrorAction Stop
            $nombre = $modulo.BaseName
            $Global:SysClipseModulos[$nombre] = $modulo.FullName
        }
        catch {
            # La importación fallida de un módulo ya no se oculta: se avisa
            # en consola para poder diagnosticar la causa real, pero no se
            # detiene el arranque del resto de la suite.
            Write-Host "[AVISO] No se pudo cargar el módulo '$($modulo.BaseName)': $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

<#
.SYNOPSIS
    Devuelve la lista de módulos cargados.
#>
function Obtener-ModulosCargados {
    [CmdletBinding()]
    [OutputType([string[]])]
    param ()
    return $Global:SysClipseModulos.Keys | Sort-Object
}

<#
.SYNOPSIS
    Despacha una acción hacia el módulo indicado.
.DESCRIPTION
    Ejecuta la función pública del módulo correspondiente. Cada módulo
    expone una función con el patrón Invoke-NombreModulo que el motor invoca.
#>
function Invoke-AccionModulo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Modulo
    )
    if (-not $Global:SysClipseModulos.ContainsKey($Modulo)) {
        return $false
    }
    $funcion = "Invoke-$Modulo"
    if (Get-Command -Name $funcion -ErrorAction SilentlyContinue) {
        & $funcion
        return $true
    }
    return $false
}

<#
.SYNOPSIS
    Inicializa el motor cargando la configuración y los módulos.
#>
function Iniciar-Motor {
    [CmdletBinding()]
    param ()
    $Global:SysClipseConfiguracion = Leer-Configuracion
    Cargar-Modulos
}

# Exportación pública del módulo.
Export-ModuleMember -Function Cargar-Modulos, Obtener-ModulosCargados, `
    Invoke-AccionModulo, Iniciar-Motor
