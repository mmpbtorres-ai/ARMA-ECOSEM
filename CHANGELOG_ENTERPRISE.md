# Cambios SIGMA Fleet Enterprise V1.0

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
