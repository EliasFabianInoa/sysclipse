# Changelog de SYSCLIPSE

Todos los cambios notables de SYSCLIPSE se documentan en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es/1.1.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

---

## [1.1.0] - 2026

### Añadido

- Centro de Recuperación ampliado con cuatro nuevas acciones:
  - Limpieza de archivos temporales (usuario, sistema y Prefetch) con informe de espacio liberado.
  - Restablecimiento de la pila de red (Winsock, TCP/IP, caché ARP y de destinos).
  - Creación de puntos de restauración del sistema con `Checkpoint-Computer`.
  - Menú interactivo de selección de acciones de recuperación.
- Auditoría de Seguridad ampliada con cinco nuevas dimensiones:
  - Estado del Control de Cuentas de Usuario (UAC) desde el registro.
  - Estado de cifrado BitLocker en todas las unidades montadas.
  - Listado de carpetas compartidas (excluyendo recursos administrativos).
  - Política de contraseñas local (longitud mínima, historial, edad máxima/mínima).
  - Historial reciente de actualizaciones instaladas con estado de cada una.
- Módulo de Instantáneas con sistema completo de comparación:
  - Captura de puntuación, servicios parados, programas de inicio y espacio por disco.
  - Guardado en archivos JSON con marca temporal.
  - Listado, visualización de detalle y comparación de dos instantáneas.
  - Diferencias visuales con indicadores de mejora o empeoramiento.
- Reportes HTML con red, BitLocker, UAC y recomendaciones ampliadas.
- Opción de instantáneas integrada en el menú principal como opción 7.
- Configuración movida a opción 8 del menú principal.
- Detección de privilegios de administrador en el Centro de Recuperación.
- Recomendación automática cuando UAC está deshabilitado.

### Cambios

- Versión actualizada de `1.0.0 Alpha` a `1.1.0`.
- `Iniciar.ps1` reescrito con secuencia de arranque que importa los ocho módulos.
- `Menu.psm1` actualizado con la nueva opción de instantáneas (7) y configuración (8).
- Reportes HTML rediseñados con gradientes, tarjetas y tipografía modernizada.

### Corregido

- `Iniciar.ps1` ahora importa correctamente los módulos de Rendimiento e Instantáneas.
- El módulo de Instantáneas es ahora accesible desde el menú principal.

---

## [1.0.0 Alpha] - 2025

### Añadido

- Arquitectura modular del proyecto con separación clara de responsabilidades.
- Núcleo de interfaz con sistema de colores uniforme (azul, verde, amarillo, rojo, cian).
- Banner y logo ASCII oficiales de SYSCLIPSE.
- Menú principal navegable con cabecera de información del sistema.
- Motor central para carga y despacho de módulos.
- Configuración centralizada en `Configuracion/Configuracion.json`.
- Módulo de Análisis de Salud con puntuación propia sobre 100.
  - Evaluación de CPU, memoria, discos, SMART, Defender, firewall, servicios y arranque.
  - Generación automática de recomendaciones.
- Módulo de Recuperación con DISM, SFC y limpieza de DNS.
- Módulo de Rendimiento con métricas de procesos y tiempo de actividad.
- Módulo de Seguridad con auditoría de Defender, firewall, usuarios y puertos.
- Módulo de Red con diagnóstico de adaptadores, IP, conectividad y DNS.
- Módulo de Reportes HTML con diseño profesional moderno.
- Módulo de Instantáneas para capturar y comparar el estado del sistema.
- Sistema de registros (logs) con marca de tiempo y niveles de severidad.
- README profesional con documentación de arquitectura y filosofía.
- Licencia MIT.

### Cambios

- Ninguno (primera versión).

### Corregido

- Ninguno (primera versión).
