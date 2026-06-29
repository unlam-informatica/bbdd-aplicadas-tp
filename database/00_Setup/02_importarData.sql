USE GestionParquesNacionales;
GO

-- ============================================================
-- 1. INDEC/APN — Catálogo de áreas protegidas
--    Archivo: C:\datasets\areas_protegidas.xlsx
-- ============================================================
DECLARE @ins1 INT, @act1 INT, @rec1 INT, @err1 INT;

EXEC Parques.uspImportarAreasProtegidas
    @insertadas   = @ins1 OUTPUT,
    @actualizadas = @act1 OUTPUT,
    @rechazadas   = @rec1 OUTPUT,
    @errores      = @err1 OUTPUT;
GO

-- ============================================================
-- 2. IGN — Coordenadas de áreas protegidas
--    Archivo: C:\datasets\areas_protegida_geo.geojson
--    Prerequisito: ejecutar bloque 1 primero.
-- ============================================================
DECLARE @act2 INT, @sin2 INT, @err2 INT;

EXEC Parques.uspImportarUbicacionesDeAreasProtegidas
    @actualizadas = @act2 OUTPUT,
    @sinMatch     = @sin2 OUTPUT,
    @errores      = @err2 OUTPUT;
GO

-- ============================================================
-- 3. datos.gob.ar — Estadísticas históricas de visitas
--    Archivo: C:\datasets\visitas.csv
-- ============================================================
DECLARE @ins3 INT, @act3 INT, @err3 INT;

EXEC Parques.uspImportarEstadisticasVisitas
    @insertados   = @ins3 OUTPUT,
    @actualizados = @act3 OUTPUT,
    @errores      = @err3 OUTPUT;
GO
