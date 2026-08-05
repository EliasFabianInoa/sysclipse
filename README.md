# SYSCLIPSE

## Suite Inteligente de Recuperación y Diagnóstico para Windows

**Analiza. Diagnostica. Recupera. Automatiza.**

---

### ¿Qué es SYSCLIPSE?

SYSCLIPSE es una suite profesional desarrollada en PowerShell 7 que permite
analizar, diagnosticar, reparar y optimizar sistemas Windows desde una consola
moderna con interfaz uniforme.

No es un script más. Es un software modular, documentado y diseñado con buenas
prácticas de ingeniería.

---

### Características principales

- **Análisis completo del sistema** con puntuación de salud propia sobre 100.
- **Centro de recuperación** con DISM, SFC, limpieza de DNS, limpieza de temporales, restablecimiento de red y puntos de restauración.
- **Analizador de rendimiento** con métricas de CPU, memoria y procesos.
- **Auditoría de seguridad** que verifica Defender, firewall, UAC, BitLocker, usuarios, puertos, carpetas compartidas, política de contraseñas e historial de actualizaciones.
- **Diagnóstico de red** con adaptadores, IP, conectividad y DNS.
- **Reportes HTML profesionales** con diseño moderno, secciones de red y seguridad ampliada.
- **Instantáneas del sistema** con captura, listado, detalle y comparación entre fechas.

---

### Puntuación de Salud

SYSCLIPSE no muestra un simple porcentaje. Calcula una puntuación propia
dividida en cuatro dimensiones:

| Dimensión       | Peso |
|-----------------|------|
| Rendimiento     | 30%  |
| Seguridad       | 30%  |
| Estabilidad     | 25%  |
| Mantenimiento   | 15%  |

Cada dimensión evalúa múltiples subsistemas y genera recomendaciones claras.

---

### Requisitos

- Windows 10/11
- PowerShell 7 o superior
- Privilegios de administrador (recomendado para recuperación)

---

### Instalación

1. Clona el repositorio.
2. Abre una terminal de PowerShell como administrador.
3. Ejecuta:

```powershell
.\Iniciar.ps1
```

---

### Arquitectura

```
SYSCLIPSE/
├── Iniciar.ps1              # Punto de entrada
├── Configuracion/
│   └── Configuracion.json   # Configuración centralizada
├── Nucleo/
│   ├── Interfaz.psm1        # Colores, banner, mensajes
│   ├── Menu.psm1            # Menú principal
│   ├── Motor.psm1           # Carga y despacho de módulos
│   └── Utilidades.psm1      # Helpers transversales
├── Modulos/
│   ├── Salud.psm1           # Análisis de salud
│   ├── Recuperacion.psm1    # DISM, SFC, DNS, temporales, red, restauración
│   ├── Rendimiento.psm1     # Métricas de rendimiento
│   ├── Seguridad.psm1       # UAC, BitLocker, firewall, puertos, contraseñas
│   ├── Red.psm1             # Diagnóstico de red
│   ├── Reportes.psm1        # Reportes HTML con red y seguridad
│   └── Instantaneas.psm1    # Captura, listado y comparación
├── Recursos/
│   ├── Banner.txt
│   └── Logo.txt
├── Reportes/
└── Registros/
```

### Flujo de arquitectura

```
Interfaz → Menú → Motor → Módulos → Sistema Operativo → Reporte
```

Ningún módulo se comunica directamente con otro. Todo pasa por el Motor.

---

### Filosofía

SYSCLIPSE nunca ejecuta acciones peligrosas sin preguntar. Siempre sigue
este flujo:

1. Escanear
2. Analizar
3. Explicar
4. Recomendar
5. Solicitar confirmación
6. Ejecutar
7. Generar registro
8. Actualizar puntuación

---

### Identidad visual

| Color   | Uso          |
|---------|--------------|
| Azul    | Información  |
| Verde   | Correcto     |
| Amarillo| Advertencias |
| Rojo    | Errores      |
| Cian    | Títulos      |

---

### Roadmap

- **v1.0.0 Alpha** - Fundación, menú, UI, motor, análisis de salud
- **v1.1.0** - Centro de recuperación ampliado, seguridad avanzada, reportes con red, instantáneas comparables
- **v2.0.0** - Motor IA para explicación de problemas

---

### Licencia

MIT - Libre uso y modificación.

---

### Autor

Desarrollado como proyecto de portafolio con calidad empresarial.
