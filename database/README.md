# Scripts SQL — Sistema de Gestión para Parques Nacionales

Scripts T-SQL organizados por **orden de ejecución**. Ejecutar en SSMS contra
**SQL Server 2022**. Para recrear la base completa desde cero: primero `ddl/00_teardown.sql`, luego los scripts en orden numérico.

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

| Script de testing | Cubre |
|-------------------|-------|
| `07_Testing/test_Concesiones.uspConcesionCreate.sql` | `03_Programabilidad/Stored Procedures/Concesiones.uspConcesionCreate.sql` |
| `07_Testing/test_Concesiones.uspConcesionPagoRegister.sql` | `03_Programabilidad/Stored Procedures/Concesiones.uspConcesionPagoRegister.sqll` |
| `07_Testing/test_Personal.uspGuardaparqueAsignarParque.sql` | `03_Programabilidad/Stored Procedures/Personal.uspGuardaparqueAsignarParque.sql` |
| `07_Testing/test_Personal.uspTourAsignarGuia.sql` | `03_Programabilidad/Stored Procedures/Personal.uspTourAsignarGuia.sql` |
| | `03_Programabilidad/Stored Procedures/criptCreateProcedures.sql` |
| `07_Testing/test_Ventas.uspVentaRegistrar.sql` | `03_Programabilidad/Stored Procedures/Ventas.uspVentaRegistrar.sql` |

La **norma de nomenclatura** está en [docs/norma-nomenclatura.md](../docs/norma-nomenclatura.md).
