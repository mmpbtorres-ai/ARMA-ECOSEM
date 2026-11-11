# SIGMA FLEET ENTERPRISE V1.0

Sistema web de gestión integral de flota y mantenimiento, adaptado sobre el proyecto SILOG original. Arquitectura Node.js + Express + PostgreSQL, interfaz web responsive y autenticación por sesión.

## Módulos
- Dashboard ejecutivo: disponibilidad, unidades, órdenes abiertas, PM vencidos, stock crítico, costos del mes y MTTR.
- Gestión de flota: vehículos y maquinaria, placa, marca, modelo, serie, estado, kilometraje y horómetro.
- Actividades diarias: registro por unidad, técnico, fecha, tipo, odómetro/horómetro, hallazgos y estado.
- Planificador PM: intervalos por días, kilómetros y horas; cálculo automático de próximo vencimiento y semáforo PROGRAMADO / PRÓXIMO / VENCIDO (umbral próximo: 90% del intervalo), con generación de OT preventiva desde el plan y actualización de la última lectura al cerrar esa OT.
- Mantenimiento preventivo y correctivo mediante órdenes de trabajo.
- Órdenes de trabajo: prioridad, técnico, programación, inicio/cierre y costos.
- Almacén y repuestos: catálogo, stock mínimo, movimientos de ingreso/consumo y trazabilidad.
- Gestión de técnicos: código, especialidad y datos de contacto.
- Costos y presupuestos: presupuesto mensual frente a ejecución registrada en órdenes cerradas o en curso según fecha.
- Reportes: exportación CSV compatible con Excel y reporte imprimible/Guardar como PDF desde el navegador.
- Login, contraseñas con scrypt, sesiones, roles ADMIN/SUPERVISOR/TECNICO/OPERADOR y auditoría.
- Base de datos PostgreSQL con historial de registros.

## Requisitos
- Windows 10/11 de 64 bits.
- Node.js 20 LTS o superior.
- PostgreSQL 14 o superior (local o servidor accesible).
- Acceso de red a PostgreSQL si la base de datos es remota.

## Instalación en Windows
1. Instale PostgreSQL y cree una base de datos llamada `sigma_fleet` (por ejemplo: `CREATE DATABASE sigma_fleet;`).
2. Instale Node.js 20 LTS o superior.
3. Descomprima el ZIP en una carpeta con permisos de escritura (recomendado: Documentos\SIGMA_FLEET).
4. Ejecute `CONFIGURAR_WINDOWS.ps1` desde PowerShell. Si la política local lo impide, abra PowerShell en la carpeta y ejecute `powershell -ExecutionPolicy Bypass -File .\CONFIGURAR_WINDOWS.ps1`.
5. Edite `.env` y configure `DATABASE_URL`, `SESSION_SECRET`, `ADMIN_USERNAME` y `ADMIN_PASSWORD`. Use una contraseña robusta y privada.
6. Ejecute `INICIAR_SIGMA.bat` y abra `http://localhost:3000`.

El esquema se crea automáticamente al iniciar. La cuenta administradora inicial se crea solo si el usuario no existe y `ADMIN_PASSWORD` está configurada. No hay credenciales predeterminadas embebidas.

## Desarrollo y verificación
```bash
npm install
npm run verify
npm start
```

## Despliegue en servidor
Configure `DATABASE_URL`, `SESSION_SECRET`, `ADMIN_USERNAME`, `ADMIN_PASSWORD` y `PORT`. En producción use HTTPS y una base de datos con copias de seguridad. Se conserva `railway.json` para despliegue en Railway.

## Reportes
- Los botones de exportación descargan CSV con codificación UTF-8 BOM, compatible con Excel.
- El reporte PDF se genera mediante la función de impresión del navegador; seleccione “Guardar como PDF”. No requiere un servicio externo.

## Consideraciones y límites
- El plan PM calcula vencimiento usando el último servicio y la lectura actual registrada de km/horómetro; por ello es necesario actualizar las lecturas operativas periódicamente.
- Los costos ejecutados provienen de los importes registrados en órdenes de trabajo; no se incluyen costos externos no registrados.
- No incluye GPS, telemetría ECU/CAN, sensores IoT, integración contable ni sincronización móvil offline. Estas integraciones requieren dispositivos, APIs y credenciales.
- El ZIP incluye código fuente y scripts de preparación para Windows; no es un instalador MSI firmado ni contiene PostgreSQL/Node.js. La instalación requiere completar los requisitos indicados.
