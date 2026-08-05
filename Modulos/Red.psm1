<#
.SYNOPSIS
    Módulo de Diagnóstico de Red de SYSCLIPSE.
.DESCRIPTION
    Analiza el estado de la red: adaptadores, direcciones IP, conectividad,
    DNS, latencia y rutas. Proporciona recomendaciones para resolver
    problemas de conectividad.
.NOTES
    Versión : 1.1.0
    Autor   : SYSCLIPSE
#>

<#
.SYNOPSIS
    Obtiene los adaptadores de red activos.
#>
function Obtener-AdaptadoresRed {
    [CmdletBinding()]
    [OutputType([array])]
    param ()
    try {
        return Get-NetAdapter -ErrorAction Stop | Where-Object { $_.Status -eq 'Up' } | Select-Object Name, InterfaceDescription, LinkSpeed
    }
    catch { return @() }
}

<#
.SYNOPSIS
    Obtiene las direcciones IP configuradas.
#>
function Obtener-DireccionesIP {
    [CmdletBinding()]
    [OutputType([array])]
    param ()
    try {
        return Get-NetIPAddress -AddressFamily IPv4 -ErrorAction Stop | Where-Object { $_.IPAddress -ne '127.0.0.1' } | Select-Object IPAddress, InterfaceAlias, PrefixLength
    }
    catch { return @() }
}

<#
.SYNOPSIS
    Comprueba la conectividad a Internet.
#>
function Probar-Conectividad {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param ()
    $resultado = @{ TieneInternet = $false; LatenciaMs = 0 }
    try {
        $ping = Test-Connection -ComputerName '8.8.8.8' -Count 1 -ErrorAction Stop
        $resultado.TieneInternet = $true
        $resultado.LatenciaMs = [int]$ping.ResponseTime
    }
    catch { }
    return $resultado
}

<#
.SYNOPSIS
    Obtiene los servidores DNS configurados.
#>
function Obtener-ServidoresDNS {
    [CmdletBinding()]
    [OutputType([array])]
    param ()
    try {
        return Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction Stop | Select-Object InterfaceAlias, ServerAddresses
    }
    catch { return @() }
}

<#
.SYNOPSIS
    Punto de entrada del módulo de Red.
#>
function Invoke-Red {
    [CmdletBinding()]
    param ()
    Preparar-Consola
    Mostrar-Titulo -Titulo 'DIAGNÓSTICO DE RED' -Ancho 70
    Escribir-Color -Texto 'Analizando la configuración de red...' -Color Azul
    Escribir-Color -Texto '' -Color Gris

    $adaptadores = Obtener-AdaptadoresRed
    $ips = Obtener-DireccionesIP
    $conectividad = Probar-Conectividad
    $dns = Obtener-ServidoresDNS

    Mostrar-Titulo -Titulo 'ADAPTADORES DE RED' -Ancho 70
    if ($adaptadores.Count -eq 0) {
        Mostrar-Aviso -Mensaje 'No se detectaron adaptadores activos.'
    }
    else {
        foreach ($a in $adaptadores) {
            Mostrar-Etiqueta -Etiqueta $a.Name -Valor $a.LinkSpeed -ColorValor Blanco
        }
    }
    Mostrar-Separador -Ancho 70 -Color Gris

    Mostrar-Titulo -Titulo 'DIRECCIONES IP' -Ancho 70
    if ($ips.Count -eq 0) {
        Mostrar-Aviso -Mensaje 'No se pudieron obtener las direcciones IP.'
    }
    else {
        foreach ($ip in $ips) {
            Mostrar-Etiqueta -Etiqueta $ip.InterfaceAlias -Valor ("{0}/{1}" -f $ip.IPAddress, $ip.PrefixLength) -ColorValor Blanco
        }
    }
    Mostrar-Separador -Ancho 70 -Color Gris

    Mostrar-Titulo -Titulo 'CONECTIVIDAD' -Ancho 70
    Mostrar-Etiqueta -Etiqueta 'Internet' -Valor $(if ($conectividad.TieneInternet) { 'Disponible' } else { 'No disponible' }) -ColorValor $(if ($conectividad.TieneInternet) { 'Verde' } else { 'Rojo' })
    if ($conectividad.TieneInternet) {
        Mostrar-Etiqueta -Etiqueta 'Latencia (8.8.8.8)' -Valor ("{0} ms" -f $conectividad.LatenciaMs) -ColorValor $(if ($conectividad.LatenciaMs -gt 100) { 'Amarillo' } else { 'Verde' })
    }
    Mostrar-Separador -Ancho 70 -Color Gris

    Mostrar-Titulo -Titulo 'SERVIDORES DNS' -Ancho 70
    if ($dns.Count -eq 0) {
        Mostrar-Aviso -Mensaje 'No se pudieron obtener los servidores DNS.'
    }
    else {
        foreach ($d in $dns) {
            $servidores = $d.ServerAddresses -join ', '
            Mostrar-Etiqueta -Etiqueta $d.InterfaceAlias -Valor $servidores -ColorValor Blanco
        }
    }
    Mostrar-Separador -Ancho 70 -Color Gris

    Escribir-Registro -Mensaje 'Diagnóstico de red completado.' -Nivel INFO
    Esperar-Tecla
}

Export-ModuleMember -Function Obtener-AdaptadoresRed, Obtener-DireccionesIP, Probar-Conectividad, Obtener-ServidoresDNS, Invoke-Red
