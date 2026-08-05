<#
.SYNOPSIS
    Módulo de Recuperación de SYSCLIPSE.
.DESCRIPTION
    Centro de recuperación del sistema. Ejecuta herramientas de reparación
    de Windows (DISM, SFC), restablece la caché de DNS, libera espacio
    temporal, restablece la pila de red y crea puntos de restauración,
    siempre solicitando confirmación previa al usuario.
.NOTES
    Versión : 1.1.0
    Autor   : SYSCLIPSE
#>

<#
.SYNOPSIS
    Ejecuta la reparación de imagen de Windows con DISM.
#>
function Reparar-ImagenWindows {
    [CmdletBinding()]
    param ()
    Mostrar-Info -Mensaje 'Ejecutando DISM /Online /Cleanup-Image /RestoreHealth...'
    try {
        $resultado = Start-Process -FilePath 'dism.exe' -ArgumentList '/Online /Cleanup-Image /RestoreHealth' -Wait -PassThru -NoNewWindow
        if ($resultado.ExitCode -eq 0) {
            Mostrar-Correcto -Mensaje 'Reparación de imagen completada correctamente.'
            Escribir-Registro -Mensaje 'DISM RestoreHealth completado.' -Nivel OK
        }
        else {
            Mostrar-Aviso -Mensaje "DISM finalizó con código de salida $($resultado.ExitCode)."
            Escribir-Registro -Mensaje "DISM RestoreHealth código $($resultado.ExitCode)." -Nivel AVISO
        }
    }
    catch {
        Mostrar-Error -Mensaje 'No se pudo ejecutar DISM.'
        Escribir-Registro -Mensaje 'Error al ejecutar DISM.' -Nivel ERROR
    }
}

<#
.SYNOPSIS
    Ejecuta el comprobador de archivos de sistema (SFC).
#>
function Reparar-ArchivosSistema {
    [CmdletBinding()]
    param ()
    Mostrar-Info -Mensaje 'Ejecutando SFC /scannow...'
    try {
        $resultado = Start-Process -FilePath 'sfc.exe' -ArgumentList '/scannow' -Wait -PassThru -NoNewWindow
        if ($resultado.ExitCode -eq 0) {
            Mostrar-Correcto -Mensaje 'Comprobación de archivos de sistema completada.'
            Escribir-Registro -Mensaje 'SFC /scannow completado.' -Nivel OK
        }
        else {
            Mostrar-Aviso -Mensaje "SFC finalizó con código de salida $($resultado.ExitCode)."
            Escribir-Registro -Mensaje "SFC /scannow código $($resultado.ExitCode)." -Nivel AVISO
        }
    }
    catch {
        Mostrar-Error -Mensaje 'No se pudo ejecutar SFC.'
        Escribir-Registro -Mensaje 'Error al ejecutar SFC.' -Nivel ERROR
    }
}

<#
.SYNOPSIS
    Vacía la caché de DNS.
#>
function Limpiar-DNS {
    [CmdletBinding()]
    param ()
    Mostrar-Info -Mensaje 'Vaciando la caché de DNS...'
    try {
        Clear-DnsClientCache -ErrorAction Stop
        Mostrar-Correcto -Mensaje 'Caché de DNS vaciada correctamente.'
        Escribir-Registro -Mensaje 'Caché de DNS vaciada.' -Nivel OK
    }
    catch {
        Mostrar-Error -Mensaje 'No se pudo vaciar la caché de DNS.'
        Escribir-Registro -Mensaje 'Error al vaciar caché de DNS.' -Nivel ERROR
    }
}

<#
.SYNOPSIS
    Libera espacio eliminando archivos temporales del usuario y del sistema.
.DESCRIPTION
    Elimina el contenido de las carpetas temporales del usuario y de
    Windows, así como la carpeta de Prefetch. Muestra el espacio liberado.
#>
function Limpiar-Temporales {
    [CmdletBinding()]
    param ()
    Mostrar-Info -Mensaje 'Limpiando archivos temporales...'
    $carpetas = @(
        $env:TEMP,
        'C:\Windows\Temp',
        'C:\Windows\Prefetch'
    )
    $espacioLiberado = 0
    $archivosEliminados = 0

    foreach ($carpeta in $carpetas) {
        if (-not (Test-Path $carpeta)) { continue }
        try {
            $archivos = Get-ChildItem -Path $carpeta -Recurse -File -Force -ErrorAction SilentlyContinue
            foreach ($archivo in $archivos) {
                $tamano = $archivo.Length
                try {
                    Remove-Item -Path $archivo.FullName -Force -ErrorAction Stop
                    $espacioLiberado += $tamano
                    $archivosEliminados++
                }
                catch {
                    # Algunos archivos están en uso y no se pueden eliminar.
                }
            }
        }
        catch { }
    }

    $espacioMB = [math]::Round($espacioLiberado / 1MB, 2)
    Mostrar-Correcto -Mensaje "Limpieza completada: $archivosEliminados archivo(s), $espacioMB MB liberados."
    Escribir-Registro -Mensaje "Limpieza de temporales: $archivosEliminados archivos, $espacioMB MB liberados." -Nivel OK
}

<#
.SYNOPSIS
    Restablece la pila de red (Winsock y TCP/IP).
.DESCRIPTION
    Ejecuta netsh winsock reset y netsh int ip reset, y vacía el ARP y el DNS.
    Requiere privilegios de administrador y reinicio del sistema.
#>
function Restablecer-Red {
    [CmdletBinding()]
    param ()
    Mostrar-Info -Mensaje 'Restableciendo la pila de red...'
    $comandos = @(
        @{ Exe = 'netsh.exe'; Args = 'winsock reset'; Desc = 'Winsock' }
        @{ Exe = 'netsh.exe'; Args = 'int ip reset'; Desc = 'TCP/IP' }
        @{ Exe = 'netsh.exe'; Args = 'int ip delete arpcache'; Desc = 'Caché ARP' }
        @{ Exe = 'netsh.exe'; Args = 'int ip delete destinationcache'; Desc = 'Caché de destinos' }
    )
    $errores = 0
    foreach ($cmd in $comandos) {
        try {
            $null = Start-Process -FilePath $cmd.Exe -ArgumentList $cmd.Args -Wait -PassThru -NoNewWindow -ErrorAction Stop
            Escribir-Color -Texto "  [OK] $($cmd.Desc) restablecido." -Color Verde
        }
        catch {
            Escribir-Color -Texto "  [X] Error al restablecer $($cmd.Desc)." -Color Rojo
            $errores++
        }
    }
    if ($errores -eq 0) {
        Mostrar-Correcto -Mensaje 'Pila de red restablecida. Reinicie el sistema para aplicar los cambios.'
        Escribir-Registro -Mensaje 'Restablecimiento de pila de red completado.' -Nivel OK
    }
    else {
        Mostrar-Aviso -Mensaje "Restablecimiento parcial ($errores error(es)). Requiere privilegios de administrador."
        Escribir-Registro -Mensaje "Restablecimiento de red con $errores error(es)." -Nivel AVISO
    }
}

<#
.SYNOPSIS
    Crea un punto de restauración del sistema.
#>
function Nuevo-PuntoRestauracion {
    [CmdletBinding()]
    param ()
    Mostrar-Info -Mensaje 'Creando punto de restauración del sistema...'
    try {
        $descripcion = "SYSCLIPSE - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $resultado = Checkpoint-Computer -Description $descripcion -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
        Mostrar-Correcto -Mensaje "Punto de restauración creado: $descripcion"
        Escribir-Registro -Mensaje "Punto de restauración creado: $descripcion" -Nivel OK
    }
    catch {
        Mostrar-Error -Mensaje 'No se pudo crear el punto de restauración. Verifique que la protección del sistema esté activada.'
        Escribir-Registro -Mensaje "Error al crear punto de restauración: $($_.Exception.Message)" -Nivel ERROR
    }
}

<#
.SYNOPSIS
    Punto de entrada del módulo de Recuperación.
#>
function Invoke-Recuperacion {
    [CmdletBinding()]
    param ()
    Preparar-Consola
    Mostrar-Titulo -Titulo 'CENTRO DE RECUPERACIÓN' -Ancho 70

    if (-not (Test-Administrador)) {
        Escribir-Color -Texto '' -Color Gris
        Mostrar-Aviso -Mensaje 'Algunas acciones requieren privilegios de administrador.'
    }

    $opciones = @(
        @{ Num = '1'; Desc = 'Reparar imagen de Windows (DISM)' }
        @{ Num = '2'; Desc = 'Comprobar archivos de sistema (SFC)' }
        @{ Num = '3'; Desc = 'Vaciar caché de DNS' }
        @{ Num = '4'; Desc = 'Limpiar archivos temporales' }
        @{ Num = '5'; Desc = 'Restablecer pila de red (Winsock + TCP/IP)' }
        @{ Num = '6'; Desc = 'Crear punto de restauración' }
        @{ Num = '0'; Desc = 'Volver al menú principal' }
    )

    Escribir-Color -Texto 'Seleccione una acción de recuperación:' -Color Azul
    Escribir-Color -Texto '' -Color Gris
    foreach ($op in $opciones) {
        $color = if ($op.Num -eq '0') { 'Rojo' } else { 'Blanco' }
        Escribir-Color -Texto ("  {0}. {1}" -f $op.Num, $op.Desc) -Color $color
    }
    Mostrar-Separador -Ancho 70 -Color Gris
    Escribir-Color -Texto 'Seleccione una opción: ' -Color Cian -SinSalto
    $opcion = Read-Host

    switch ($opcion.Trim()) {
        '1' {
            if (Confirmar-Accion -Pregunta '¿Desea ejecutar DISM? Puede tardar varios minutos.') {
                Reparar-ImagenWindows
            }
        }
        '2' {
            if (Confirmar-Accion -Pregunta '¿Desea ejecutar SFC? Puede tardar varios minutos.') {
                Reparar-ArchivosSistema
            }
        }
        '3' {
            if (Confirmar-Accion -Pregunta '¿Desea vaciar la caché de DNS?') {
                Limpiar-DNS
            }
        }
        '4' {
            if (Confirmar-Accion -Pregunta '¿Desea limpiar los archivos temporales?') {
                Limpiar-Temporales
            }
        }
        '5' {
            if (Confirmar-Accion -Pregunta '¿Desea restablecer la pila de red? Requiere reinicio posterior.') {
                Restablecer-Red
            }
        }
        '6' {
            if (Confirmar-Accion -Pregunta '¿Desea crear un punto de restauración del sistema?') {
                Nuevo-PuntoRestauracion
            }
        }
        '0' { return }
        default { Mostrar-Aviso -Mensaje 'Opción no válida.' }
    }
    Esperar-Tecla
}

Export-ModuleMember -Function Reparar-ImagenWindows, Reparar-ArchivosSistema, Limpiar-DNS, `
    Limpiar-Temporales, Restablecer-Red, Nuevo-PuntoRestauracion, Invoke-Recuperacion
