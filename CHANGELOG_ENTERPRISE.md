# Cambios SIGMA Fleet Enterprise V1.1

Base: SIGMA_Fleet_Adaptado_Modelo_SILOG.

- Se conserva la arquitectura Express + PostgreSQL, autenticación y módulos existentes.
- Se incorpora el registro de actividades diarias.
- Se incorpora el maestro de técnicos y su asignación a actividades.
- Se amplía el plan PM con vencimiento por fecha, kilometraje y horómetro, estados y generación de OT desde el plan.
- Al cerrar una OT generada desde PM se actualizan las lecturas de referencia del plan asociado.
- Se incorpora presupuesto mensual y comparación con costos ejecutados.
- Se incorporan reportes CSV compatibles con Excel y reporte imprimible a PDF.
- Se incorpora preparación de instalación en Windows (PowerShell, BAT e Inno Setup script).
- Se añade carga de variables desde `.env` mediante dotenv.


## Cambios 1.1.0 — Railway / control operativo

- Se conserva PostgreSQL como almacenamiento central para trabajar desde el dominio web de Railway.
- Se agregan programas general y semanal editables.
- Se agregan reportes de estatus diarios por turno y actualización de condición operativa.
- Se agrega cronograma de engrase y bitácora de engrase ejecutado.
- Se agrega control documental con frecuencia, evento, estado, versión, responsable, destinatario y enlace.
- Se agrega historial de salidas de mantenimiento, retiros de obra, relevos y solicitudes de Costos.
- Se generan entradas de control documental desde eventos operativos.
- Se agregan exportaciones CSV de los módulos nuevos y health check para Railway.
