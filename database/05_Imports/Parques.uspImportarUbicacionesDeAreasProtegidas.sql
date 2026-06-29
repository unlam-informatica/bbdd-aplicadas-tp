/* ============================================================
Universidad Nacional de La Matanza
Bases de Datos Aplicada - 3641 - Comisión 2900
Grupo: 1
Integrantes:
     - Arenas Velasco, Artin Leonel
     - Rios, Marcos Adrían
     - Romano, Jorge Dario

Fecha: 28/06/2026
Objetivo: Importación de coordenadas de referencia (Latitud / Longitud) para
          parques ya existentes en el sistema, a partir del GeoJSON oficial
          del Instituto Geográfico Nacional (Fuente 2).

          Fuente: Instituto Geográfico Nacional (IGN)
          Capa:   Áreas Protegidas  (area_protegida)
          Archivo: area_protegida.geojson
          Total de features: 506 (áreas de todas las jurisdicciones)

          Propiedades del GeoJSON usadas:
            fna  = nombre completo oficial del área protegida
            gna  = tipo genérico del área
            nam  = nombre corto
            bbox = [lon_min, lat_min, lon_max, lat_max]

          Coordenada de referencia: centroide del bounding box (bbox).
          La geometría original no se almacena; solo la coordenada de referencia.

          Estrategia de matching (determinística, sin fuzzy):
            1. Exact match CI_AI: fna del GeoJSON = Nombre en Parques.Parque
            2. Tabla Importacion.EquivalenciaNombreFuente para excepciones.
          Los features que no matchean se registran como errores para revisión manual.
          Este SP NO crea parques nuevos; solo actualiza coordenadas de existentes.

          Prerequisito:
            - Ejecutar 00_InfraestructuraImportacion.sql antes.
            - Ejecutar Parques.uspImportarAreasProtegidas primero
              para que los parques APN existan en el sistema.
            - El archivo debe estar accesible para la cuenta de servicio de SQL Server.

          Nota sobre encoding:
            El GeoJSON está codificado en UTF-8. OPENROWSET BULK SINGLE_CLOB
            lee el archivo con el codepage del servidor (tipicamente Latin1).
            Los caracteres con tilde pueden no leerse correctamente en servidores
            con collation Latin1. En ese caso, convertir el archivo a ANSI/Latin-1
            antes de importar o registrar las equivalencias en EquivalenciaNombreFuente.
============================================================ */

USE GestionParquesNacionales;
GO

-- Tabla de staging para features del GeoJSON de IGN
IF OBJECT_ID('Importacion.StgAreasProtegidasGeoJson', 'U') IS NULL
    CREATE TABLE Importacion.StgAreasProtegidasGeoJson (
        StgId            INT            IDENTITY(1,1) NOT NULL,
        ImportacionId    INT            NOT NULL,
        GidIGN           INT            NULL,
        NombreCompleto   NVARCHAR(300)  NULL,
        TipoGenerico     NVARCHAR(200)  NULL,
        NombreCorto      NVARCHAR(200)  NULL,
        BboxLonMin       DECIMAL(12,8)  NULL,
        BboxLatMin       DECIMAL(12,8)  NULL,
        BboxLonMax       DECIMAL(12,8)  NULL,
        BboxLatMax       DECIMAL(12,8)  NULL,
        LatitudCalc      DECIMAL(9,6)   NULL,
        LongitudCalc     DECIMAL(9,6)   NULL,
        CONSTRAINT PK_StgAreasProtegidasGeoJson PRIMARY KEY (StgId)
    );
GO

CREATE OR ALTER PROCEDURE Parques.uspImportarUbicacionesDeAreasProtegidas
    @archivo      NVARCHAR(4000),
    @actualizadas INT = 0 OUTPUT,
    @sinMatch     INT = 0 OUTPUT,
    @errores      INT = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validación del parámetro
    IF NULLIF(LTRIM(RTRIM(@archivo)), N'') IS NULL
        THROW 60040, 'El parámetro @archivo no puede ser nulo o vacío.', 1;

    IF LOWER(RIGHT(LTRIM(RTRIM(@archivo)), 8)) <> N'.geojson'
        THROW 60041, 'El archivo debe tener extensión .geojson.', 1;

    -- Registrar inicio en auditoría
    DECLARE @importacionId INT;

    INSERT INTO Importacion.AuditoriaImportacion
        (Fuente, NombreArchivo, FechaInicio, Estado)
    VALUES
        ('IGN GeoJSON', @archivo, GETDATE(), 'EN_PROCESO');

    SET @importacionId = SCOPE_IDENTITY();

    -- Leer el GeoJSON completo como texto.
    -- SQL dinámico necesario: la ruta es un parámetro.
    -- SINGLE_CLOB lee como VARCHAR(MAX) con el codepage del servidor.
    DECLARE @json    NVARCHAR(MAX);
    DECLARE @sqlRead NVARCHAR(MAX) =
        N'SELECT @j = CAST(BulkColumn AS NVARCHAR(MAX))
          FROM OPENROWSET(BULK N''' + REPLACE(@archivo, N'''', N'''''') + N''', SINGLE_CLOB) AS x';

    BEGIN TRY
        EXEC sp_executesql @sqlRead, N'@j NVARCHAR(MAX) OUTPUT', @j = @json OUTPUT;
    END TRY
    BEGIN CATCH
        UPDATE Importacion.AuditoriaImportacion
        SET FechaFin = GETDATE(), Estado = 'FALLIDO',
            MensajeError = ERROR_MESSAGE()
        WHERE ImportacionId = @importacionId;

        THROW 60042,
            'Error al leer el archivo GeoJSON. Verifique la ruta y los permisos.',
            1;
    END CATCH;

    IF ISJSON(@json) = 0
    BEGIN
        UPDATE Importacion.AuditoriaImportacion
        SET FechaFin = GETDATE(), Estado = 'FALLIDO',
            MensajeError = 'El archivo no contiene JSON válido.'
        WHERE ImportacionId = @importacionId;

        THROW 60043, 'El archivo no contiene JSON válido o no pudo leerse correctamente.', 1;
    END;

    -- Cargar staging: parsear features y calcular centroide del bbox
    TRUNCATE TABLE Importacion.StgAreasProtegidasGeoJson;

    INSERT INTO Importacion.StgAreasProtegidasGeoJson
        (ImportacionId, GidIGN, NombreCompleto, TipoGenerico, NombreCorto,
         BboxLonMin, BboxLatMin, BboxLonMax, BboxLatMax,
         LatitudCalc, LongitudCalc)
    SELECT
        @importacionId,
        TRY_CAST(JSON_VALUE(f.value, '$.properties.gid') AS INT),
        JSON_VALUE(f.value, '$.properties.fna'),
        JSON_VALUE(f.value, '$.properties.gna'),
        JSON_VALUE(f.value, '$.properties.nam'),
        TRY_CAST(JSON_VALUE(f.value, '$.bbox[0]') AS DECIMAL(12,8)),   -- lon min (W)
        TRY_CAST(JSON_VALUE(f.value, '$.bbox[1]') AS DECIMAL(12,8)),   -- lat min (S)
        TRY_CAST(JSON_VALUE(f.value, '$.bbox[2]') AS DECIMAL(12,8)),   -- lon max (E)
        TRY_CAST(JSON_VALUE(f.value, '$.bbox[3]') AS DECIMAL(12,8)),   -- lat max (N)
        -- Centroide del bbox: promedio lat
        (TRY_CAST(JSON_VALUE(f.value, '$.bbox[1]') AS DECIMAL(12,8)) +
         TRY_CAST(JSON_VALUE(f.value, '$.bbox[3]') AS DECIMAL(12,8))) / 2.0,
        -- Centroide del bbox: promedio lon
        (TRY_CAST(JSON_VALUE(f.value, '$.bbox[0]') AS DECIMAL(12,8)) +
         TRY_CAST(JSON_VALUE(f.value, '$.bbox[2]') AS DECIMAL(12,8))) / 2.0
    FROM OPENJSON(@json, '$.features') AS f;

    DECLARE @filasLeidas INT = (SELECT COUNT(*) FROM Importacion.StgAreasProtegidasGeoJson
                                WHERE ImportacionId = @importacionId);

    -- Matching: intentar asociar cada feature a un parque del sistema.
    -- Estrategia 1: exact CI_AI match entre fna e IgnNombreCompleto y Parques.Parque.Nombre.
    -- Estrategia 2: Lookup en EquivalenciaNombreFuente para excepciones registradas.
    SELECT
        s.StgId,
        s.NombreCompleto,
        s.NombreCorto,
        s.LatitudCalc,
        s.LongitudCalc,
        COALESCE(
            -- Estrategia 1: match exacto CI_AI
            (SELECT TOP 1 p.ParqueId
             FROM Parques.Parque p
             WHERE p.Nombre COLLATE SQL_Latin1_General_CP1_CI_AI
                   = s.NombreCompleto COLLATE SQL_Latin1_General_CP1_CI_AI),
            -- Estrategia 2: tabla de equivalencias
            (SELECT TOP 1 e.ParqueId
             FROM Importacion.EquivalenciaNombreFuente e
             WHERE e.FuenteOrigen = 'IGN GeoJSON'
               AND e.NombreOrigen COLLATE SQL_Latin1_General_CP1_CI_AI
                   = s.NombreCompleto COLLATE SQL_Latin1_General_CP1_CI_AI
               AND e.Activo = 1)
        ) AS ParqueIdMatch
    INTO #Matches
    FROM Importacion.StgAreasProtegidasGeoJson s
    WHERE s.ImportacionId = @importacionId
      AND s.LatitudCalc  IS NOT NULL
      AND s.LongitudCalc IS NOT NULL;

    DECLARE @filasConBbox INT = (SELECT COUNT(*) FROM #Matches);

    -- Actualizar coordenadas de parques matcheados
    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE p WITH (UPDLOCK, HOLDLOCK)
        SET
            p.Latitud                = m.LatitudCalc,
            p.Longitud               = m.LongitudCalc,
            p.FuenteImportacion      = ISNULL(p.FuenteImportacion, '') +
                                       CASE WHEN p.FuenteImportacion IS NOT NULL
                                            THEN ' + IGN GeoJSON' ELSE 'IGN GeoJSON' END,
            p.FechaUltimaImportacion = GETDATE()
        FROM Parques.Parque p
        INNER JOIN #Matches m ON m.ParqueIdMatch = p.ParqueId;

        SET @actualizadas = @@ROWCOUNT;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

        UPDATE Importacion.AuditoriaImportacion
        SET FechaFin = GETDATE(), Estado = 'FALLIDO',
            MensajeError = ERROR_MESSAGE()
        WHERE ImportacionId = @importacionId;

        THROW;
    END CATCH;

    -- Registrar features sin match como errores para revisión manual
    SET @sinMatch = (SELECT COUNT(*) FROM #Matches WHERE ParqueIdMatch IS NULL);

    INSERT INTO Importacion.ErrorImportacion
        (ImportacionId, NumeroFila, NombreArchivo, Campo, ValorOriginal, Descripcion)
    SELECT
        @importacionId,
        m.StgId,
        @archivo,
        'fna',
        m.NombreCompleto,
        'No se encontró un parque con este nombre en el sistema. ' +
        'Registrar equivalencia en Importacion.EquivalenciaNombreFuente si corresponde.'
    FROM #Matches m
    WHERE m.ParqueIdMatch IS NULL;

    -- Features con bbox nulo (no se puede calcular centroide)
    DECLARE @sinBbox INT = @filasLeidas - @filasConBbox;

    SET @errores = @sinMatch + @sinBbox;

    -- Actualizar auditoría
    UPDATE Importacion.AuditoriaImportacion
    SET
        FechaFin     = GETDATE(),
        FilasLeidas  = @filasLeidas,
        FilasValidas = @actualizadas,
        Actualizadas = @actualizadas,
        Rechazadas   = @sinMatch,
        Estado       = CASE WHEN @errores > 0 THEN 'CON_ERRORES' ELSE 'OK' END
    WHERE ImportacionId = @importacionId;

    -- Reporte de features sin match
    IF @sinMatch > 0
    BEGIN
        PRINT 'Features IGN sin match en el sistema (' + CAST(@sinMatch AS VARCHAR) + ' registros):';
        SELECT m.NombreCompleto, m.NombreCorto,
               m.LatitudCalc, m.LongitudCalc
        FROM #Matches m
        WHERE m.ParqueIdMatch IS NULL
        ORDER BY m.NombreCompleto;
    END;

    -- Resumen
    SELECT
        @archivo       AS Archivo,
        @filasLeidas   AS FeaturesLeidos,
        @actualizadas  AS ParquesActualizados,
        @sinMatch      AS FeaturesSinMatch,
        @sinBbox       AS FeaturesSinBbox,
        @errores       AS TotalSinProcesar,
        GETDATE()      AS FechaEjecucion;
END;
GO

PRINT 'SP Parques.uspImportarUbicacionesDeAreasProtegidas creado exitosamente.';
GO
