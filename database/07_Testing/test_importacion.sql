/* ============================================================
Universidad Nacional de La Matanza
Bases de Datos Aplicada - 3641 - Comisión 2900
Grupo: 1
Integrantes:
     - Arenas Velasco, Artin Leonel
     - Rios, Marcos Adrían
     - Romano, Jorge Dario

Fecha: 28/06/2026
Objetivo: Scripts de testing para los cuatro stored procedures de importación
          masiva de la Entrega 6.

          SPs probados:
            1. Parques.uspImportarAreasProtegidas   (XLSX INDEC/APN)
            2. Parques.uspImportarUbicacionesDeAreasProtegidas     (GeoJSON IGN)
            3. Parques.uspImportarEstadisticasVisitas         (CSV datos.gob.ar)

          ANTES DE EJECUTAR: ajustar las variables de ruta en cada bloque
          a la ubicación real de los archivos en el servidor SQL Server.
          Los archivos deben ser accesibles por la cuenta de servicio de SQL Server.

          ORDEN DE EJECUCIÓN RECOMENDADO:
            Bloque 1 (Excel) → Bloque 2 (GeoJSON) → Bloque 3 (CSV)
============================================================ */

USE GestionParquesNacionales;
GO

-- ============================================================
-- BLOQUE 1: Parques.uspImportarAreasProtegidas
-- Fuente: INDEC/APN - Anuario Estadístico 2024
-- Archivo: indec_areas_protegidas_2024.xlsx
-- ============================================================
PRINT '=== TEST 1: uspImportarAreasProtegidas ===';
GO

-- 1.1 Validación: parámetro nulo
PRINT '-- 1.1 Parámetro nulo: debe lanzar error 60030';
BEGIN TRY
    EXEC Parques.uspImportarAreasProtegidas @archivo = NULL;
    PRINT 'ERROR: debería haber fallado.';
END TRY
BEGIN CATCH
    PRINT 'OK - Error capturado: ' + ERROR_MESSAGE();
END CATCH;
GO

-- 1.2 Validación: extensión incorrecta
PRINT '-- 1.2 Extensión incorrecta: debe lanzar error 60031';
BEGIN TRY
    EXEC Parques.uspImportarAreasProtegidas @archivo = N'C:\datasets\archivo.csv';
    PRINT 'ERROR: debería haber fallado.';
END TRY
BEGIN CATCH
    PRINT 'OK - Error capturado: ' + ERROR_MESSAGE();
END CATCH;
GO

-- 1.3 Primera importación con el archivo real
-- Ajustar @ruta a la ubicación del archivo en el servidor.
PRINT '-- 1.3 Primera ejecución: inserción del catálogo APN (~77 áreas protegidas)';

DECLARE @ruta1 NVARCHAR(4000) = N'C:\datasets\indec_areas_protegidas_2024.xlsx';
DECLARE @ins1 INT, @act1 INT, @rec1 INT, @err1 INT;

EXEC Parques.uspImportarAreasProtegidas
    @archivo    = @ruta1,
    @insertadas   = @ins1   OUTPUT,
    @actualizadas = @act1   OUTPUT,
    @rechazadas   = @rec1   OUTPUT,
    @errores      = @err1   OUTPUT;

PRINT 'Insertadas:   ' + CAST(@ins1 AS VARCHAR);
PRINT 'Actualizadas: ' + CAST(@act1 AS VARCHAR);
PRINT 'Rechazadas:   ' + CAST(@rec1 AS VARCHAR);
PRINT 'Errores:      ' + CAST(@err1 AS VARCHAR);
-- Resultado esperado: ins1 > 0 (primero que no estaban), act1 >= 0, err1 = 0
GO

-- 1.4 Verificar parques importados
PRINT '-- 1.4 Verificar parques insertados por la fuente XLSX';
SELECT ParqueId, Nombre, TipoParque, Ecorregion,
       AnioCreacion, Superficie, FuenteImportacion
FROM Parques.Parque
WHERE FuenteImportacion = 'INDEC/APN XLSX'
ORDER BY TipoParque, Nombre;
GO

-- 1.5 Idempotencia: segunda ejecución con el mismo archivo
PRINT '-- 1.5 Segunda ejecución (idempotencia): 0 inserciones, solo actualizaciones';

DECLARE @ruta1b NVARCHAR(4000) = N'C:\datasets\indec_areas_protegidas_2024.xlsx';
DECLARE @ins2 INT, @act2 INT, @rec2 INT, @err2 INT;

EXEC Parques.uspImportarAreasProtegidas
    @archivo      = @ruta1b,
    @insertadas   = @ins2   OUTPUT,
    @actualizadas = @act2   OUTPUT,
    @rechazadas   = @rec2   OUTPUT,
    @errores      = @err2   OUTPUT;

SELECT
    @ins2 AS Insertadas_DeberiaSerCero,
    @act2 AS Actualizadas,
    @rec2 AS Rechazadas,
    @err2 AS Errores;
-- Resultado esperado: Insertadas = 0, Actualizadas = total parques, Errores = 0
GO

-- ============================================================
-- BLOQUE 2: Parques.uspImportarUbicacionesDeAreasProtegidas
-- Fuente: IGN - Capa áreas protegidas
-- Archivo: area_protegida.geojson
-- ============================================================
PRINT '=== TEST 2: uspImportarUbicacionesDeAreasProtegidas ===';
GO

-- 2.1 Validación: extensión incorrecta
PRINT '-- 2.1 Extensión incorrecta: debe lanzar error 60041';
BEGIN TRY
    EXEC Parques.uspImportarUbicacionesDeAreasProtegidas @archivo = N'C:\datasets\archivo.json';
    PRINT 'ERROR: debería haber fallado.';
END TRY
BEGIN CATCH
    PRINT 'OK - Error capturado: ' + ERROR_MESSAGE();
END CATCH;
GO

-- 2.2 Primera importación con el archivo real
PRINT '-- 2.2 Primera ejecución: actualizar Latitud/Longitud de parques con datos IGN';

DECLARE @ruta2 NVARCHAR(4000) = N'C:\datasets\area_protegida.geojson';
DECLARE @act3 INT, @sinM3 INT, @err3 INT;

EXEC Parques.uspImportarUbicacionesDeAreasProtegidas
    @archivo      = @ruta2,
    @actualizadas = @act3  OUTPUT,
    @sinMatch     = @sinM3 OUTPUT,
    @errores      = @err3  OUTPUT;

PRINT 'Parques actualizados: ' + CAST(@act3 AS VARCHAR);
PRINT 'Features sin match:   ' + CAST(@sinM3 AS VARCHAR);
PRINT 'Total sin procesar:   ' + CAST(@err3 AS VARCHAR);
-- Resultado esperado: act3 > 0 (parques con coordenadas IGN), sinM3 > 0 (areas no APN)
GO

-- 2.3 Verificar coordenadas actualizadas
PRINT '-- 2.3 Parques con coordenadas actualizadas por IGN';
SELECT Nombre, Latitud, Longitud, TipoParque, FuenteImportacion
FROM Parques.Parque
WHERE Latitud IS NOT NULL AND Longitud IS NOT NULL
ORDER BY Nombre;
GO

-- 2.4 Idempotencia: segunda ejecución
PRINT '-- 2.4 Segunda ejecución (idempotencia): mismos parques actualizados, sin duplicados';

DECLARE @ruta2b NVARCHAR(4000) = N'C:\datasets\area_protegida.geojson';
DECLARE @act4 INT, @sinM4 INT, @err4 INT;

EXEC Parques.uspImportarUbicacionesDeAreasProtegidas
    @archivo      = @ruta2b,
    @actualizadas = @act4  OUTPUT,
    @sinMatch     = @sinM4 OUTPUT,
    @errores      = @err4  OUTPUT;

SELECT @act4 AS Actualizadas, @sinM4 AS SinMatch, @err4 AS Errores;
GO

-- ============================================================
-- BLOQUE 3: Parques.uspImportarEstadisticasVisitas
-- Fuente: datos.yvera.gob.ar
-- Archivo: visitas-residentes-y-no-residentes.csv
-- ============================================================
PRINT '=== TEST 3: uspImportarEstadisticasVisitas ===';
GO

-- 3.1 Ruta inválida
PRINT '-- 3.1 Archivo inexistente: debe capturar error 60010';
BEGIN TRY
    EXEC Parques.uspImportarEstadisticasVisitas
        @archivo = N'C:\ruta\inexistente\visitas.csv';
    PRINT 'ERROR: debería haber fallado.';
END TRY
BEGIN CATCH
    PRINT 'OK - Error capturado: ' + ERROR_MESSAGE();
END CATCH;
GO

-- 3.2 Primera importación (~660 filas históricas desde 2008)
PRINT '-- 3.2 Primera ejecución: carga histórica completa';

DECLARE @ruta4 NVARCHAR(500) = N'C:\datasets\visitas-residentes-y-no-residentes.csv';
DECLARE @ins7 INT, @act7 INT, @err7 INT;

EXEC Parques.uspImportarEstadisticasVisitas
    @archivo      = @ruta4,
    @insertados   = @ins7 OUTPUT,
    @actualizados = @act7 OUTPUT,
    @errores      = @err7 OUTPUT;

PRINT 'Insertados:   ' + CAST(@ins7 AS VARCHAR);
PRINT 'Actualizados: ' + CAST(@act7 AS VARCHAR);
PRINT 'Errores:      ' + CAST(@err7 AS VARCHAR);
-- Resultado esperado: insertados ~660, actualizados 0, errores 0
GO

-- 3.3 Verificar primer período disponible (2008-01)
PRINT '-- 3.3 Verificar datos del primer período';
SELECT Anio, Mes, OrigenVisitante, CantidadVisitas
FROM Parques.EstadisticaVisitasNacional
WHERE Anio = 2008 AND Mes = 1
ORDER BY OrigenVisitante;
-- Resultado esperado: 3 filas (no_residentes, residentes, total)
GO

-- 3.4 Idempotencia: segunda ejecución
PRINT '-- 3.4 Segunda ejecución (idempotencia): 0 inserciones';

DECLARE @ruta4b NVARCHAR(500) = N'C:\datasets\visitas-residentes-y-no-residentes.csv';
DECLARE @ins8 INT, @act8 INT, @err8 INT;

EXEC Parques.uspImportarEstadisticasVisitas
    @archivo      = @ruta4b,
    @insertados   = @ins8 OUTPUT,
    @actualizados = @act8 OUTPUT,
    @errores      = @err8 OUTPUT;

SELECT
    @ins8 AS Insertados_DeberiaSerCero,
    @act8 AS Actualizados,
    @err8 AS Errores;
GO

-- 3.5 Verificar CHECK constraint de la tabla destino
PRINT '-- 3.5 CHECK constraint rechaza slug inválido';
BEGIN TRY
    INSERT INTO Parques.EstadisticaVisitasNacional (Anio, Mes, OrigenVisitante, CantidadVisitas)
    VALUES (2026, 1, 'extranjeros', 99999);
    PRINT 'ERROR: debería haber fallado.';
END TRY
BEGIN CATCH
    PRINT 'OK - CHECK constraint funciona: ' + ERROR_MESSAGE();
END CATCH;
GO

-- ============================================================
-- RESUMEN FINAL
-- ============================================================
PRINT '=== RESUMEN FINAL DE IMPORTACIONES ===';

SELECT
    (SELECT COUNT(*) FROM Parques.Parque)                                           AS TotalParques,
    (SELECT COUNT(*) FROM Parques.Parque WHERE FuenteImportacion IS NOT NULL)       AS ParquesImportados,
    (SELECT COUNT(*) FROM Parques.Parque WHERE Latitud IS NOT NULL)                 AS ConCoordenadas,
    (SELECT COUNT(*) FROM Parques.EstadisticaVisitasNacional)                       AS TotalEstadisticas,
    (SELECT COUNT(*) FROM Importacion.AuditoriaImportacion WHERE Estado = 'OK')     AS ImportacionesOK,
    (SELECT COUNT(*) FROM Importacion.AuditoriaImportacion WHERE Estado = 'CON_ERRORES') AS ImportacionesConErrores,
    (SELECT COUNT(*) FROM Importacion.ErrorImportacion)                             AS TotalErroresRegistrados;
GO

-- Historial de ejecuciones
PRINT '=== Historial de auditoría ===';
SELECT
    ImportacionId, Fuente,
    FechaInicio, FechaFin,
    FilasLeidas, Insertadas, Actualizadas, Rechazadas,
    Estado
FROM Importacion.AuditoriaImportacion
ORDER BY ImportacionId;
GO
