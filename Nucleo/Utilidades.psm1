<#
.SYNOPSIS
    Utilidades transversales de SYSCLIPSE.
.DESCRIPTION
    Funciones de apoyo para lectura de configuración, gestión de registros
    (logs), obtención de información del sistema y helpers de formato.
.NOTES
    Versión : 1.1.0
    Autor   : SYSCLIPSE
#>

<#
.SYNOPSIS
    Carga la configuración centralizada desde Configuracion/Configuracion.json.
#>
function Leer-Configuracion {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param ()
    $ruta = Join-Path $Global:SysClipseRutaRaiz 'Configuracion/Configuracion.json'
    if (-not (Test-Path $ruta)) {
        return @{}
    }
    try {
        $json = Get-Content -Path $ruta -Raw -Encoding UTF8 | ConvertFrom-Json
        $tabla = @{}
        foreach ($propiedad in $json.PSObject.Properties) {
            $tabla[$propiedad.Name] = $propiedad.Value
        }
        return $tabla
    }
    catch {
        return @{}
    }
}

<#
.SYNOPSIS
    Escribe una entrada en el registro (log) del día actual.
#>
function Escribir-Registro {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Mensaje,

        [ValidateSet('INFO', 'OK', 'AVISO', 'ERROR')]
        [string]$Nivel = 'INFO'
    )
    $carpeta = Join-Path $Global:SysClipseRutaRaiz 'Registros'
    if (-not (Test-Path $carpeta)) {
        New-Item -Path $carpeta -ItemType Directory -Force | Out-Null
    }
    $fecha = Get-Date -Format 'yyyy-MM-dd'
    $ruta = Join-Path $carpeta "SYSCLIPSE_$fecha.log"
    $marcaTiempo = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $linea = "[$marcaTiempo] [$Nivel] $Mensaje"
    Add-Content -Path $ruta -Value $linea -Encoding UTF8
}

<#
.SYNOPSIS
    Obtiene información básica del equipo y del sistema operativo.
.OUTPUTS
    Hashtable con NombreEquipo, SistemaOperativo, Version, Arquitectura, Usuario.
#>
function Obtener-InfoSistema {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param ()
    $info = @{
        NombreEquipo       = $env:COMPUTERNAME
        SistemaOperativo   = 'Desconocido'
        Version            = 'Desconocida'
        Arquitectura       = $env:PROCESSOR_ARCHITECTURE
        Usuario            = $env:USERNAME
        Dominio            = $env:USERDOMAIN
    }
    try {
        $so = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $info.SistemaOperativo = $so.Caption
        $info.Version = $so.Version
    }
    catch {
        # En sistemas sin WMI disponible se mantienen los valores por defecto.
    }
    return $info
}

<#
.SYNOPSIS
    Obtiene la fecha y hora actual formateada en español.
#>
function Obtener-FechaFormateada {
    [CmdletBinding()]
    [OutputType([string])]
    param ()
    $cultura = [System.Globalization.CultureInfo]::GetCultureInfo('es-ES')
    return (Get-Date).ToString('dddd, dd ''de'' MMMM ''de'' yyyy - HH:mm', $cultura)
}

<#
.SYNOPSIS
    Convierte un valor numérico de bytes a una cadena legible (KB, MB, GB).
#>
function Formatear-Tamano {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [long]$Bytes
    )
    $unidades = @('B', 'KB', 'MB', 'GB', 'TB', 'PB')
    $indice = 0
    $valor = [double]$Bytes
    while ($valor -ge 1024 -and $indice -lt $unidades.Count - 1) {
        $valor /= 1024
        $indice++
    }
    return ('{0:N2} {1}' -f $valor, $unidades[$indice])
}

<#
.SYNOPSIS
    Garantiza que una carpeta exista, creándola si es necesario.
#>
function Asegurar-Carpeta {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Ruta
    )
    if (-not (Test-Path $Ruta)) {
        New-Item -Path $Ruta -ItemType Directory -Force | Out-Null
    }
}

<#
.SYNOPSIS
    Evalúa si la consola actual tiene privilegios de administrador.
#>
function Test-Administrador {
    [CmdletBinding()]
    [OutputType([bool])]
    param ()
    try {
        $identidad = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object System.Security.Principal.WindowsPrincipal($identidad)
        return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

# Exportación pública del módulo.
Export-ModuleMember -Function Leer-Configuracion, Escribir-Registro, Obtener-InfoSistema, `
    Obtener-FechaFormateada, Formatear-Tamano, Asegurar-Carpeta, Test-Administrador
