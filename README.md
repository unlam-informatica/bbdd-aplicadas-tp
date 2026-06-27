# Sistema de Gestión de Parques Nacionales

Trabajo Práctico Integrador de la materia **Bases de Datos Aplicada** (3641) de la
carrera Ingeniería en Informática — [Universidad Nacional de La Matanza (UNLaM)](https://www.unlam.edu.ar).

El sistema centraliza la gestión de los parques nacionales: venta de entradas,
actividades y tours, concesiones, personal (guardaparques y guías), importación de
datos públicos y reportes.

## Información del proyecto

|  |  |
| --- | --- |
| **Universidad** | Universidad Nacional de La Matanza |
| **Materia** | Bases de Datos Aplicada — 3641 |
| **Comisión** | 2900 |
| **Cuatrimestre** | 1º Cuatrimestre 2026 |
| **Grupo** | 1 |
| **Integrantes** | <ul><li>Arenas Velasco, Artin Leonel</li><li>Leguizamon Sarmiento, Juan Andrés</li><li>Rios, Marcos Adrián</li><li>Romano, Jorge Darío</li></ul> |

## Stack técnico

- **Motor**: Microsoft SQL Server 2022 (16.x) Standard Edition
- **S.O. servidor**: Windows Server 2022
- **Cliente**: SQL Server Management Studio (SSMS)

## Estructura del repositorio

```
database/
├── 00_Setup/               ← definición de la base de datos (ejecutar en orden)
├── 01_DDL/                 ← definición de la base de datos (ejecutar en orden)
├── 02_Seguridad/           ← Login, Usuarios y Permisos
├── 03_Programabilidad/     ← stored procedures abm business (E5)
├── 04_Data/                ← inicializacion de datos de la tabla (E5)
├── 05_Imports/             ← stored procedures de impotación (E6)
├── 06_Reportes/            ← stored procedures de reportes (E7)
└── 07_Testing/             ← scripts de testing 1:1 con cada script de SPs (E5, E6...)
datasets/                   ← archivos CSV/XML de datos externos
docs/                       ← documentación (norma de nomenclatura, DER)
```

## Orden de ejecución — inicialización completa (database/ddl/)

| # | Script | Entrega | Contenido |
|---|--------|---------|-----------|
| — | `00_teardown.sql` | — | Elimina la base existente (si existe) |
| 1 | `01_base_esquemas.sql` | E5 | Crea la base `GestionParquesNacionales` y los esquemas |
| 2 | `02_tablas.sql` | E5 | Todas las tablas + restricciones + índices |
| 3 | `Schema.[NombreSP].sql` | E5 | Stored procedures ABM de todas las entidades |
| 4 | `Schema.[NombreSP].sql` | E5 | SPs de lógica de negocio (transaccionales) |
| 5 | `Schema.[NombreFuncion].sql` | E5 | Funciones escalares y de tabla |
| 6 | `Schema.[NombreVista].sql` | E5 | Vistas del sistema |
| 7 | `Roles.sql` | E8 | Roles y permisos granulares |
| 8 | `Cifrado.sql` | E8 | Cifrado de datos sensibles |
| 9 | `datos_iniciales.sql` | E9 | Juego de datos inicial (seed) |

## Scripts independientes (no forman parte de la inicialización)

| Script | Entrega | Contenido |
|--------|---------|-----------|
| `importacion/sp_importacion.sql` | E6 | SPs de importación masiva (upsert, sin duplicados) |
| `reportes/sp_reportes.sql` | E7 | SPs de reportes (al menos dos retornan XML) |

> Estos scripts se ejecutan una vez que la base está inicializada (luego del paso 9).

## Testing (1:1 con los scripts de SPs)

| Script de testing (07_Testing) | Cubre (03_Programabilidad/Stored Procedures/) |
|-------------------|-------|
| `test_Concesiones.uspConcesionCreate.sql` | `Concesiones.uspConcesionCreate.sql` |
| `test_Concesiones.uspConcesionPagoRegister.sql` | `Concesiones.uspConcesionPagoRegister.sqll` |
| `test_Personal.uspGuardaparqueAsignarParque.sql` | `Personal.uspGuardaparqueAsignarParque.sql` |
| `test_Personal.uspTourAsignarGuia.sql` | `Personal.uspTourAsignarGuia.sql` |
| | `scriptCreateProcedures.sql` |
| `test_Ventas.uspVentaRegistrar.sql` | `Ventas.uspVentaRegistrar.sql` |

La **norma de nomenclatura** está en [docs/norma-nomenclatura.md](../docs/norma-nomenclatura.md).

## Entregas

| Entrega | Contenido | Estado |
| --- | --- | --- |
| E5 | Base de datos + SPs ABM y de negocio | En progreso |
| E6 | Proceso de importación (upsert, sin duplicados) | Pendiente |
| E7 | Reportes (al menos 2 retornan XML) | Pendiente |
| E8 | Seguridad (cifrado + roles + backup) | Pendiente |
| E9 | BI + aplicación + datos semilla (≥10 parques, 30 actividades, 20 guías…) | Pendiente |
