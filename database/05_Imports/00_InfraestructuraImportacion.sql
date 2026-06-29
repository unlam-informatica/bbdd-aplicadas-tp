/* ============================================================
Universidad Nacional de La Matanza
Bases de Datos Aplicada - 3641 - Comisión 2900
Grupo: 1
Integrantes:
     - Arenas Velasco, Artin Leonel
     - Rios, Marcos Adrían
     - Romano, Jorge Dario

Fecha: 28/06/2026
Objetivo: Infraestructura compartida para el módulo de importación masiva
          (Entrega 6). Crea el esquema Importacion y las tablas de auditoría,
          errores y equivalencias de nombres usadas por todos los SPs de
          importación.

          Orden de ejecución: ANTES de cualquier SP de importación.
============================================================ */

USE GestionParquesNacionales;
GO

-- Esquema Importacion (staging, auditoría, errores)
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Importacion')
    EXEC ('CREATE SCHEMA Importacion');
GO

-- ----------------------------------------------------------------------------
-- Auditoría de ejecuciones de importación
-- Una fila por llamada a cualquier SP de importación.
-- ----------------------------------------------------------------------------
IF OBJECT_ID('Importacion.AuditoriaImportacion', 'U') IS NULL
    CREATE TABLE Importacion.AuditoriaImportacion (
        ImportacionId INT           IDENTITY(1,1) NOT NULL,
        Fuente        VARCHAR(100)  NOT NULL,
        NombreArchivo NVARCHAR(500) NOT NULL,
        FechaInicio   DATETIME      NOT NULL,
        FechaFin      DATETIME      NULL,
        FilasLeidas   INT           NULL,
        FilasValidas  INT           NULL,
        Insertadas    INT           NULL,
        Actualizadas  INT           NULL,
        Rechazadas    INT           NULL,
        Estado        VARCHAR(20)   NOT NULL,
        MensajeError  NVARCHAR(2000) NULL,
        CONSTRAINT PK_AuditoriaImportacion
            PRIMARY KEY (ImportacionId),
        CONSTRAINT CK_AuditoriaImportacion_Estado
            CHECK (Estado IN ('EN_PROCESO', 'OK', 'CON_ERRORES', 'FALLIDO'))
    );
GO

-- ----------------------------------------------------------------------------
-- Errores persistentes por fila de importación
-- Vinculados a su ejecución mediante ImportacionId.
-- ----------------------------------------------------------------------------
IF OBJECT_ID('Importacion.ErrorImportacion', 'U') IS NULL
    CREATE TABLE Importacion.ErrorImportacion (
        ErrorId       INT           IDENTITY(1,1) NOT NULL,
        ImportacionId INT           NOT NULL,
        NumeroFila    INT           NULL,
        NombreArchivo NVARCHAR(500) NOT NULL,
        FechaError    DATETIME      NOT NULL CONSTRAINT DF_ErrorImportacion_FechaError DEFAULT GETDATE(),
        Campo         VARCHAR(100)  NOT NULL,
        ValorOriginal NVARCHAR(500) NULL,
        Descripcion   NVARCHAR(1000) NOT NULL,
        CONSTRAINT PK_ErrorImportacion
            PRIMARY KEY (ErrorId),
        CONSTRAINT FK_ErrorImportacion_Auditoria
            FOREIGN KEY (ImportacionId)
            REFERENCES Importacion.AuditoriaImportacion(ImportacionId)
    );
GO

-- ----------------------------------------------------------------------------
-- Tabla de equivalencias entre nombres de fuentes externas y parques del sistema.
-- Permite resolver manualmente los casos donde el nombre en la fuente no
-- coincide con el nombre en Parques.Parque (e.g. diferencia de clasificación).
-- Ejemplo:
--   FuenteOrigen='IGN GeoJSON', NombreOrigen='Parque Nacional Iberá', ParqueId=5
-- ----------------------------------------------------------------------------
IF OBJECT_ID('Importacion.EquivalenciaNombreFuente', 'U') IS NULL
    CREATE TABLE Importacion.EquivalenciaNombreFuente (
        EquivalenciaId INT          IDENTITY(1,1) NOT NULL,
        FuenteOrigen   VARCHAR(50)  NOT NULL,
        NombreOrigen   NVARCHAR(250) NOT NULL,
        ParqueId       INT          NOT NULL,
        Activo         BIT          NOT NULL CONSTRAINT DF_EquivalenciaNombreFuente_Activo DEFAULT 1,
        CONSTRAINT PK_EquivalenciaNombreFuente
            PRIMARY KEY (EquivalenciaId),
        CONSTRAINT UQ_EquivalenciaNombreFuente
            UNIQUE (FuenteOrigen, NombreOrigen),
        CONSTRAINT FK_EquivalenciaNombreFuente_Parque
            FOREIGN KEY (ParqueId) REFERENCES Parques.Parque(ParqueId)
    );
GO

PRINT 'Infraestructura de importacion creada/verificada exitosamente.';
GO
