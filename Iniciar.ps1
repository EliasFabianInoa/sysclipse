<#
.SYNOPSIS
    Punto de entrada de SYSCLIPSE.
.DESCRIPTION
    Inicializa el entorno, define las rutas globales, importa los módulos
    del núcleo, arranca el motor y presenta el menú principal.
.NOTES
    Versión : 1.1.0
    Autor   : SYSCLIPSE
#>

# ============================================================================
# Configuración de entorno
# ============================================================================
$ErrorActionPreference = 'Stop'

Write-Host "[VERIFICACION] Ejecutando Iniciar.ps1 CORREGIDO desde: $PSCommandPath" -ForegroundColor Magenta

# Definición de rutas globales del proyecto.
$Global:SysClipseRutaRaiz = $PSScriptRoot
$Global:SysClipseRutaNucleo = Join-Path $PSScriptRoot 'Nucleo'
$Global:SysClipseRutaModulos = Join-Path $PSScriptRoot 'Modulos'
$Global:SysClipseRutaRecursos = Join-Path $PSScriptRoot 'Recursos'

# ============================================================================
# Importación de módulos del núcleo
# ============================================================================
Import-Module (Join-Path $Global:SysClipseRutaNucleo 'Interfaz.psm1') -Force
Import-Module (Join-Path $Global:SysClipseRutaNucleo 'Utilidades.psm1') -Force
Import-Module (Join-Path $Global:SysClipseRutaNucleo 'Motor.psm1') -Force
Import-Module (Join-Path $Global:SysClipseRutaNucleo 'Menu.psm1') -Force

# ============================================================================
# Secuencia de arranque
# ============================================================================
Preparar-Consola
Mostrar-Banner

Escribir-Color -Texto 'Inicializando módulos...' -Color Azul
Escribir-Color -Texto '' -Color Gris

$modulosArranque = @(
    @{ Nombre = 'Interfaz';      Ruta = 'Nucleo/Interfaz.psm1' }
    @{ Nombre = 'Motor';         Ruta = 'Nucleo/Motor.psm1' }
    @{ Nombre = 'Diagnóstico';   Ruta = 'Modulos/Salud.psm1' }
    @{ Nombre = 'Recuperación';  Ruta = 'Modulos/Recuperacion.psm1' }
    @{ Nombre = 'Rendimiento';   Ruta = 'Modulos/Rendimiento.psm1' }
    @{ Nombre = 'Seguridad';     Ruta = 'Modulos/Seguridad.psm1' }
    @{ Nombre = 'Red';           Ruta = 'Modulos/Red.psm1' }
    @{ Nombre = 'Reportes';      Ruta = 'Modulos/Reportes.psm1' }
    @{ Nombre = 'Instantáneas';  Ruta = 'Modulos/Instantaneas.psm1' }
)

foreach ($modulo in $modulosArranque) {
    $rutaCompleta = Join-Path $Global:SysClipseRutaRaiz $modulo.Ruta
    try {
        Import-Module -Name $rutaCompleta -Force -Global -ErrorAction Stop
        Escribir-Color -Texto "  [OK] $($modulo.Nombre)" -Color Verde
    }
    catch {
        Escribir-Color -Texto "  [ERROR] $($modulo.Nombre) -> $($_.Exception.Message)" -Color Rojo
    }
    Start-Sleep -Milliseconds 80
}

Escribir-Color -Texto '' -Color Gris
Mostrar-Correcto -Mensaje 'Inicialización completada.'
Escribir-Color -Texto '' -Color Gris

# Inicializar el motor (carga configuración y módulos funcionales).
Iniciar-Motor

# Verificación de diagnóstico: confirma si la función crítica del módulo
# de Salud quedó realmente disponible después de la carga del motor.
if (Get-Command -Name 'Obtener-PuntuacionSalud' -ErrorAction SilentlyContinue) {
    Escribir-Color -Texto '[OK] Obtener-PuntuacionSalud está disponible.' -Color Verde
}
else {
    Escribir-Color -Texto '[ERROR] Obtener-PuntuacionSalud NO está disponible tras Iniciar-Motor.' -Color Rojo
}

# Registrar el arranque en el log.
Escribir-Registro -Mensaje 'SYSCLIPSE iniciado correctamente.' -Nivel INFO

# ============================================================================
# Lanzar menú principal
# ============================================================================
Start-Sleep -Milliseconds 500
Mostrar-MenuPrincipal

# ============================================================================
# Cierre ordenado
# ============================================================================
Preparar-Consola
Mostrar-Banner
Escribir-Color -Texto 'Gracias por usar SYSCLIPSE.' -Color Cian
Escribir-Color -Texto 'Suite Inteligente de Recuperación y Diagnóstico para Windows' -Color Azul
Escribir-Color -Texto '' -Color Gris
Escribir-Registro -Mensaje 'SYSCLIPSE cerrado.' -Nivel INFO
