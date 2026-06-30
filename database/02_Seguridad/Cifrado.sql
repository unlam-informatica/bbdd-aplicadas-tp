/* ============================================================
Universidad Nacional de La Matanza
Bases de Datos Aplicada - 3641 - Comisión 2900
Grupo: 1
Integrantes:
     - Arenas Velasco, Artin Leonel
     - Rios, Marcos Adrían
     - Romano, Jorge Dario

Fecha: 30/06/2026

Objetivo: Entrega 8 - Cifrado de datos sensibles.
   Datos sensibles identificados: Dni (Personal.Guia, Personal.Guardaparque,
   Ventas.Visitante) y Cuit (Concesiones.Concesion), por tratarse de datos
   de identificacion personal/fiscal unica.
   No se cifran nombres/apellidos (necesarios en reportes) ni montos
   (se consideran datos comerciales, no de identificacion personal).
 
   El script:
     1) Crea la infraestructura de cifrado (Master Key, Certificado, Clave Simetrica).
     2) Crea funciones auxiliares de cifrado/descifrado/hash.
     3) Migra la ESTRUCTURA y los DATOS YA EXISTENTES de las 4 columnas sensibles.
     4) Modifica los Stored Procedures existentes (scriptCreateProcedures.sql)
        que insertan, actualizan o copian estas columnas, para que cifren/
        descifren usando las funciones auxiliares.
     5) Agrega Stored Procedures de consulta que descifran los datos.
============================================================ */

USE GestionParquesNacionales;
GO
 
-- ================================================================
-- 1) GENREACION DE CONTRASEÑA PARA LA BASE, CERTIFICADOS Y CLAVES SIMETRICAS
-- ================================================================

IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'hs73djSD#_#DH8372sad';
GO
 
IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = 'Cert_DatosSensibles')
    CREATE CERTIFICATE Cert_DatosSensibles
        WITH SUBJECT = 'Certificado para cifrado de DNI y CUIT - GestionParquesNacionales';
GO
 
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = 'SK_DatosSensibles')
    CREATE SYMMETRIC KEY SK_DatosSensibles
        WITH ALGORITHM = AES_256
        ENCRYPTION BY CERTIFICATE Cert_DatosSensibles;
GO
 
-- ================================================================
-- 2) FUNCIONES DE ENCRIPTACION/DESENCRIPTACION
-- ================================================================
 
CREATE OR ALTER FUNCTION dbo.ufnEncriptar (@Valor VARCHAR(50))
RETURNS VARBINARY(128)
AS
BEGIN
    RETURN ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), @Valor);
END
GO
 
CREATE OR ALTER FUNCTION dbo.ufnDesencriptar (@ValorCifrado VARBINARY(128))
RETURNS VARCHAR(50)
AS
BEGIN
    RETURN CONVERT(VARCHAR(50), DECRYPTBYKEY(@ValorCifrado));
END
GO
 
-- Hash determinístico (SHA2_256): permite validar unicidad y buscar
-- por Dni/Cuit sin poder revertir el valor original (no es cifrado).
CREATE OR ALTER FUNCTION dbo.ufnHashDato (@Valor VARCHAR(50))
RETURNS VARBINARY(32)
AS
BEGIN
    RETURN HASHBYTES('SHA2_256', @Valor);
END
GO
 
-- ================================================================
-- 3) MIGRACION DE ESTRUCTURA Y DATOS EXISTENTES
--    Patron: agregar columnas nuevas -> cifrar/hashear datos
--    existentes -> borrar constraint vieja -> borrar columna vieja
--    -> renombrar -> NOT NULL -> recrear constraint sobre el hash.
--    Cada bloque valida si ya se ejecuto (COL_LENGTH) para ser
--    idempotente.
-- ================================================================
 
-- ----------------------------------------------------------------
-- 3.1) Personal.Guia.Dni  (tenia UQ_Guia_Dni)
-- ----------------------------------------------------------------
IF COL_LENGTH('Personal.Guia', 'DniCifrado') IS NULL
    ALTER TABLE Personal.Guia ADD DniCifrado VARBINARY(128) NULL;
GO
 
IF COL_LENGTH('Personal.Guia', 'DniHash') IS NULL
    ALTER TABLE Personal.Guia ADD DniHash VARBINARY(32) NULL;
GO
 
IF COL_LENGTH('Personal.Guia', 'DniCifrado') IS NOT NULL
BEGIN
    OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE Cert_DatosSensibles;
 
    UPDATE Personal.Guia
    SET DniCifrado = dbo.ufnEncriptar(CONVERT(VARCHAR(20), Dni)),
        DniHash    = dbo.ufnHashDato(CONVERT(VARCHAR(20), Dni))
    WHERE DniCifrado IS NULL;
 
    CLOSE SYMMETRIC KEY SK_DatosSensibles;
END
GO
 
IF COL_LENGTH('Personal.Guia', 'DniCifrado') IS NOT NULL
BEGIN
    IF OBJECT_ID('Personal.UQ_Guia_Dni', 'UQ') IS NOT NULL
        ALTER TABLE Personal.Guia DROP CONSTRAINT UQ_Guia_Dni;
 
    ALTER TABLE Personal.Guia DROP COLUMN Dni;
    EXEC sp_rename 'Personal.Guia.DniCifrado', 'Dni', 'COLUMN';
END
GO
 
IF COLUMNPROPERTY(OBJECT_ID('Personal.Guia'), 'Dni', 'AllowsNull') = 1
    ALTER TABLE Personal.Guia ALTER COLUMN Dni VARBINARY(128) NOT NULL;
GO
 
IF COLUMNPROPERTY(OBJECT_ID('Personal.Guia'), 'DniHash', 'AllowsNull') = 1
    ALTER TABLE Personal.Guia ALTER COLUMN DniHash VARBINARY(32) NOT NULL;
GO
 
IF OBJECT_ID('Personal.UQ_Guia_DniHash', 'UQ') IS NULL
    ALTER TABLE Personal.Guia ADD CONSTRAINT UQ_Guia_DniHash UNIQUE (DniHash);
GO
 
PRINT 'Personal.Guia: Dni migrado a cifrado.';
GO
 
-- ----------------------------------------------------------------
-- 3.2) Personal.Guardaparque.Dni  (no tenia UNIQUE)
-- ----------------------------------------------------------------
IF COL_LENGTH('Personal.Guardaparque', 'DniCifrado') IS NULL
    ALTER TABLE Personal.Guardaparque ADD DniCifrado VARBINARY(128) NULL;
GO
 
IF COL_LENGTH('Personal.Guardaparque', 'DniHash') IS NULL
    ALTER TABLE Personal.Guardaparque ADD DniHash VARBINARY(32) NULL;
GO
 
IF COL_LENGTH('Personal.Guardaparque', 'DniCifrado') IS NOT NULL
BEGIN
    OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE Cert_DatosSensibles;
 
    UPDATE Personal.Guardaparque
    SET DniCifrado = dbo.ufnEncriptar(CONVERT(VARCHAR(20), Dni)),
        DniHash    = dbo.ufnHashDato(CONVERT(VARCHAR(20), Dni))
    WHERE DniCifrado IS NULL;
 
    CLOSE SYMMETRIC KEY SK_DatosSensibles;
END
GO
 
IF COL_LENGTH('Personal.Guardaparque', 'DniCifrado') IS NOT NULL
BEGIN
    ALTER TABLE Personal.Guardaparque DROP COLUMN Dni;
    EXEC sp_rename 'Personal.Guardaparque.DniCifrado', 'Dni', 'COLUMN';
END
GO
 
IF COLUMNPROPERTY(OBJECT_ID('Personal.Guardaparque'), 'Dni', 'AllowsNull') = 1
    ALTER TABLE Personal.Guardaparque ALTER COLUMN Dni VARBINARY(128) NOT NULL;
GO
 
IF COLUMNPROPERTY(OBJECT_ID('Personal.Guardaparque'), 'DniHash', 'AllowsNull') = 1
    ALTER TABLE Personal.Guardaparque ALTER COLUMN DniHash VARBINARY(32) NOT NULL;
GO
 
PRINT 'Personal.Guardaparque: Dni migrado a cifrado.';
GO
 
-- ----------------------------------------------------------------
-- 3.3) Ventas.Visitante.Dni  (tenia UQ_Visitante_Dni)
-- ----------------------------------------------------------------
IF COL_LENGTH('Ventas.Visitante', 'DniCifrado') IS NULL
    ALTER TABLE Ventas.Visitante ADD DniCifrado VARBINARY(128) NULL;
GO
 
IF COL_LENGTH('Ventas.Visitante', 'DniHash') IS NULL
    ALTER TABLE Ventas.Visitante ADD DniHash VARBINARY(32) NULL;
GO
 
IF COL_LENGTH('Ventas.Visitante', 'DniCifrado') IS NOT NULL
BEGIN
    OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE Cert_DatosSensibles;
 
    UPDATE Ventas.Visitante
    SET DniCifrado = dbo.ufnEncriptar(CONVERT(VARCHAR(20), Dni)),
        DniHash    = dbo.ufnHashDato(CONVERT(VARCHAR(20), Dni))
    WHERE DniCifrado IS NULL;
 
    CLOSE SYMMETRIC KEY SK_DatosSensibles;
END
GO
 
IF COL_LENGTH('Ventas.Visitante', 'DniCifrado') IS NOT NULL
BEGIN
    IF OBJECT_ID('Ventas.UQ_Visitante_Dni', 'UQ') IS NOT NULL
        ALTER TABLE Ventas.Visitante DROP CONSTRAINT UQ_Visitante_Dni;
 
    ALTER TABLE Ventas.Visitante DROP COLUMN Dni;
    EXEC sp_rename 'Ventas.Visitante.DniCifrado', 'Dni', 'COLUMN';
END
GO
 
IF COLUMNPROPERTY(OBJECT_ID('Ventas.Visitante'), 'Dni', 'AllowsNull') = 1
    ALTER TABLE Ventas.Visitante ALTER COLUMN Dni VARBINARY(128) NOT NULL;
GO
 
IF COLUMNPROPERTY(OBJECT_ID('Ventas.Visitante'), 'DniHash', 'AllowsNull') = 1
    ALTER TABLE Ventas.Visitante ALTER COLUMN DniHash VARBINARY(32) NOT NULL;
GO
 
IF OBJECT_ID('Ventas.UQ_Visitante_DniHash', 'UQ') IS NULL
    ALTER TABLE Ventas.Visitante ADD CONSTRAINT UQ_Visitante_DniHash UNIQUE (DniHash);
GO
 
PRINT 'Ventas.Visitante: Dni migrado a cifrado.';
GO
 
-- ----------------------------------------------------------------
-- 3.4) Concesiones.Concesion.Cuit  (no tenia UNIQUE)
-- ----------------------------------------------------------------
IF COL_LENGTH('Concesiones.Concesion', 'CuitCifrado') IS NULL
    ALTER TABLE Concesiones.Concesion ADD CuitCifrado VARBINARY(128) NULL;
GO
 
IF COL_LENGTH('Concesiones.Concesion', 'CuitHash') IS NULL
    ALTER TABLE Concesiones.Concesion ADD CuitHash VARBINARY(32) NULL;
GO
 
IF COL_LENGTH('Concesiones.Concesion', 'CuitCifrado') IS NOT NULL
BEGIN
    OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE Cert_DatosSensibles;
 
    UPDATE Concesiones.Concesion
    SET CuitCifrado = dbo.ufnEncriptar(CONVERT(VARCHAR(20), Cuit)),
        CuitHash    = dbo.ufnHashDato(CONVERT(VARCHAR(20), Cuit))
    WHERE CuitCifrado IS NULL;
 
    CLOSE SYMMETRIC KEY SK_DatosSensibles;
END
GO
 
IF COL_LENGTH('Concesiones.Concesion', 'CuitCifrado') IS NOT NULL
BEGIN
    ALTER TABLE Concesiones.Concesion DROP COLUMN Cuit;
    EXEC sp_rename 'Concesiones.Concesion.CuitCifrado', 'Cuit', 'COLUMN';
END
GO
 
IF COLUMNPROPERTY(OBJECT_ID('Concesiones.Concesion'), 'Cuit', 'AllowsNull') = 1
    ALTER TABLE Concesiones.Concesion ALTER COLUMN Cuit VARBINARY(128) NOT NULL;
GO
 
IF COLUMNPROPERTY(OBJECT_ID('Concesiones.Concesion'), 'CuitHash', 'AllowsNull') = 1
    ALTER TABLE Concesiones.Concesion ALTER COLUMN CuitHash VARBINARY(32) NOT NULL;
GO
 
PRINT 'Concesiones.Concesion: Cuit migrado a cifrado.';
GO
 
-- ================================================================
-- 4) MODIFICACION DE STORED PROCEDURES EXISTENTES
-- ================================================================
 
-- ----------------------------------------------------------------
-- 4.1) Personal.uspGuiaAlta
-- ----------------------------------------------------------------
CREATE OR ALTER PROCEDURE Personal.uspGuiaAlta(
    @Nombre               VARCHAR(100),
    @Apellido             VARCHAR(100),
    @Dni                  INT,
    @Titulo               VARCHAR(100),
    @Especialidad         VARCHAR(100),
    @VigenciaAutorizacion DATE
)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @ERRORES VARCHAR(MAX) = '';
    DECLARE @DniHash VARBINARY(32) = dbo.ufnHashDato(CONVERT(VARCHAR(20), @Dni));
 
    IF @Nombre IS NULL OR LTRIM(RTRIM(@Nombre)) = ''
        SET @ERRORES += 'El campo nombre no puede estar vacio.' + CHAR(13) + CHAR(10);
 
    IF @Apellido IS NULL OR LTRIM(RTRIM(@Apellido)) = ''
        SET @ERRORES += 'El campo apellido no puede estar vacio.' + CHAR(13) + CHAR(10);
 
    IF @Dni < 1
        SET @ERRORES += 'El campo DNI debe ser un numero positivo.' + CHAR(13) + CHAR(10);
 
    IF EXISTS (SELECT 1 FROM Personal.Guia WHERE DniHash = @DniHash)
        SET @ERRORES += 'Ya existe un guia registrado con ese DNI.' + CHAR(13) + CHAR(10);
 
    IF @Especialidad IS NULL OR LTRIM(RTRIM(@Especialidad)) = ''
        SET @ERRORES += 'El campo especialidad no puede estar vacio.' + CHAR(13) + CHAR(10);
 
    IF @VigenciaAutorizacion IS NULL
        SET @ERRORES += 'La vigencia de autorizacion no puede ser nula.' + CHAR(13) + CHAR(10);
 
    IF @VigenciaAutorizacion < CAST(GETDATE() AS DATE)
        SET @ERRORES += 'La vigencia de autorizacion no puede ser una fecha pasada.' + CHAR(13) + CHAR(10);
 
    IF @ERRORES <> ''
        THROW 50001, @ERRORES, 1;
 
    OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE Cert_DatosSensibles;
 
    INSERT INTO Personal.Guia (Nombre, Apellido, Dni, DniHash, Titulo, Especialidad, VigenciaAutorizacion)
    VALUES (@Nombre, @Apellido, dbo.ufnEncriptar(CONVERT(VARCHAR(20), @Dni)), @DniHash, @Titulo, @Especialidad, @VigenciaAutorizacion);
 
    CLOSE SYMMETRIC KEY SK_DatosSensibles;
 
    SELECT SCOPE_IDENTITY() AS IdCreado;
END
GO
 
-- Personal.uspGuiaModificar y Personal.uspGuiaBaja no tocan Dni: sin cambios.
 
-- ----------------------------------------------------------------
-- 4.2) Personal.uspGuardaparqueAlta
-- ----------------------------------------------------------------
CREATE OR ALTER PROCEDURE Personal.uspGuardaparqueAlta(
    @Nombre              VARCHAR(100),
    @Apellido            VARCHAR(100),
    @Dni                 INT,
    @FechaIngresoSistema DATE,
    @FechaEgresoSistema  DATE = NULL,
    @Activo              BIT  = 1,
    @ParqueId            INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @ERRORES VARCHAR(MAX) = '';
 
    IF @Nombre IS NULL OR LTRIM(RTRIM(@Nombre)) = ''
        SET @ERRORES += 'El campo nombre no puede estar vacio.' + CHAR(13) + CHAR(10);
 
    IF @Apellido IS NULL OR LTRIM(RTRIM(@Apellido)) = ''
        SET @ERRORES += 'El campo apellido no puede estar vacio.' + CHAR(13) + CHAR(10);
 
    IF @Dni < 1
        SET @ERRORES += 'El campo DNI debe ser un numero positivo.' + CHAR(13) + CHAR(10);
 
    IF @FechaIngresoSistema IS NULL
        SET @ERRORES += 'La fecha de ingreso no puede ser nula.' + CHAR(13) + CHAR(10);
 
    IF @FechaEgresoSistema IS NOT NULL AND DATEDIFF(DAY, @FechaIngresoSistema, @FechaEgresoSistema) < 0
        SET @ERRORES += 'La fecha de egreso no puede ser anterior a la fecha de ingreso.' + CHAR(13) + CHAR(10);
 
    IF @Activo IS NULL
        SET @ERRORES += 'El campo activo no puede ser nulo.' + CHAR(13) + CHAR(10);
 
    IF @ERRORES <> ''
        THROW 50001, @ERRORES, 1;
 
    OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE Cert_DatosSensibles;
 
    INSERT INTO Personal.Guardaparque(Nombre, Apellido, Dni, DniHash, FechaIngresoSistema, FechaEgresoSistema, EsActivo, ParqueId)
    VALUES (
        @Nombre, @Apellido,
        dbo.ufnEncriptar(CONVERT(VARCHAR(20), @Dni)),
        dbo.ufnHashDato(CONVERT(VARCHAR(20), @Dni)),
        @FechaIngresoSistema, @FechaEgresoSistema, @Activo, @ParqueId
    );
 
    CLOSE SYMMETRIC KEY SK_DatosSensibles;
 
    SELECT SCOPE_IDENTITY() AS IdCreado;
END
GO
  
-- ----------------------------------------------------------------
-- 4.3) Personal.uspAsignarGuardaparque
-- ----------------------------------------------------------------
CREATE OR ALTER PROCEDURE Personal.uspAsignarGuardaparque
	@GuardaparqueIdActual INT,
	@ParqueIdNuevo INT,
	@FechaAsignacion DATE = NULL,
	@GuardaparqueIdNuevo INT = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
 
	DECLARE @MensajeError NVARCHAR(4000);
	DECLARE @ParqueIdActual INT;
	DECLARE @FechaIngresoActual DATE;
 
	BEGIN TRY
		IF @FechaAsignacion IS NULL
		BEGIN
			SET @FechaAsignacion = CAST(GETDATE() AS DATE);
		END;
 
		IF NOT EXISTS (
			SELECT 1
			FROM Personal.Guardaparque
			WHERE GuardaparqueId = @GuardaparqueIdActual
			  AND EsActivo = 1
			  AND FechaEgresoSistema IS NULL
		)
		BEGIN
			SET @MensajeError = 'El guardaparque con ID ' + CAST(@GuardaparqueIdActual AS NVARCHAR(10)) + ' no existe o no tiene asignación activa.';
			THROW 50031, @MensajeError, 1;
		END;
 
		IF NOT EXISTS (
			SELECT 1
			FROM Parques.Parque
			WHERE ParqueId = @ParqueIdNuevo
			  AND EsActivo = 1
		)
		BEGIN
			SET @MensajeError = 'El parque destino con ID ' + CAST(@ParqueIdNuevo AS NVARCHAR(10)) + ' no existe o no está activo.';
			THROW 50032, @MensajeError, 1;
		END;
 
		SELECT
			@ParqueIdActual = ParqueId,
			@FechaIngresoActual = FechaIngresoSistema
		FROM Personal.Guardaparque
		WHERE GuardaparqueId = @GuardaparqueIdActual;
 
		IF @ParqueIdActual = @ParqueIdNuevo
		BEGIN
			THROW 50033, 'El parque destino debe ser diferente al parque actual.', 1;
		END;
 
		IF @FechaAsignacion < @FechaIngresoActual
		BEGIN
			THROW 50034, 'La fecha de asignación no puede ser anterior a la fecha de ingreso de la asignación actual.', 1;
		END;
 
		BEGIN TRANSACTION;
 
		UPDATE Personal.Guardaparque
		SET FechaEgresoSistema = @FechaAsignacion,
			EsActivo = 0
		WHERE GuardaparqueId = @GuardaparqueIdActual
		  AND EsActivo = 1
		  AND FechaEgresoSistema IS NULL;
 
		IF @@ROWCOUNT = 0
		BEGIN
			THROW 50035, 'No se pudo cerrar la asignación anterior del guardaparque.', 1;
		END;
 
		INSERT INTO Personal.Guardaparque
			(Nombre, Apellido, Dni, DniHash, FechaIngresoSistema, FechaEgresoSistema, EsActivo, ParqueId)
		SELECT
			Nombre,
			Apellido,
			Dni,
			DniHash,
			@FechaAsignacion,
			NULL,
			1,
			@ParqueIdNuevo
		FROM Personal.Guardaparque
		WHERE GuardaparqueId = @GuardaparqueIdActual;
 
		SET @GuardaparqueIdNuevo = SCOPE_IDENTITY();
 
		COMMIT TRANSACTION;
 
		PRINT 'Reasignación creada exitosamente con GuardaparqueId: ' + CAST(@GuardaparqueIdNuevo AS NVARCHAR(20));
	END TRY
	BEGIN CATCH
		IF XACT_STATE() <> 0
		BEGIN
			ROLLBACK TRANSACTION;
		END;
		THROW;
	END CATCH
END;
GO
 
-- ----------------------------------------------------------------
-- 4.4) Concesiones.uspConcesionAlta
-- ----------------------------------------------------------------
CREATE OR ALTER PROCEDURE Concesiones.uspConcesionAlta
    @ParqueId INT,
    @Cuit BIGINT,
    @EmpresaConcesionaria VARCHAR(150),
    @TipoActividad VARCHAR(100),
    @FechaInicio DATE,
    @FechaFin DATE,
    @CanonMensual DECIMAL(18,6),
    @ConcesionId INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @msg NVARCHAR(4000);
 
    BEGIN TRY
        IF NOT EXISTS (
            SELECT 1
            FROM Parques.Parque
            WHERE ParqueId = @ParqueId AND EsActivo = 1
        )
        BEGIN
            SET @msg =
                'El parque con ID '
                + ISNULL(CAST(@ParqueId AS VARCHAR(10)), 'NULL')
                + ' no existe o no está activo.';
 
            THROW 50001, @msg, 1;
        END;
 
        IF @EmpresaConcesionaria IS NULL
           OR LTRIM(RTRIM(@EmpresaConcesionaria)) = ''
        BEGIN
            THROW 50002,
                'El nombre de la empresa concesionaria no puede estar vacío.',
                1;
        END;
 
        IF @Cuit <= 0
        BEGIN
            THROW 50003,
                'El CUIT debe ser un número válido.',
                1;
        END;
 
        IF @FechaInicio >= @FechaFin
        BEGIN
            THROW 50004,
                'La fecha de inicio debe ser menor que la fecha de fin.',
                1;
        END;
 
        IF @CanonMensual <= 0
        BEGIN
            THROW 50005,
                'El canon mensual debe ser un valor positivo.',
                1;
        END;
 
        OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE Cert_DatosSensibles;
 
        INSERT INTO Concesiones.Concesion
            (ParqueId, Cuit, CuitHash, EmpresaConcesionaria, TipoActividad, FechaInicio, FechaFin, CanonMensual, EsActivo)
        VALUES
            (@ParqueId,
             dbo.ufnEncriptar(CONVERT(VARCHAR(20), @Cuit)),
             dbo.ufnHashDato(CONVERT(VARCHAR(20), @Cuit)),
             @EmpresaConcesionaria, @TipoActividad, @FechaInicio, @FechaFin, @CanonMensual, 1);
 
        CLOSE SYMMETRIC KEY SK_DatosSensibles;
 
        SET @ConcesionId = SCOPE_IDENTITY();
 
        PRINT 'Concesión creada exitosamente con ID: ' + CAST(@ConcesionId AS VARCHAR);
 
    END TRY
    BEGIN CATCH
        IF EXISTS (SELECT 1 FROM sys.openkeys WHERE key_name = 'SK_DatosSensibles')
            CLOSE SYMMETRIC KEY SK_DatosSensibles;
        THROW;
    END CATCH
END;
GO
  
-- ----------------------------------------------------------------
-- 4.5) Ventas.uspVisitanteAlta
-- ----------------------------------------------------------------
CREATE OR ALTER PROCEDURE Ventas.uspVisitanteAlta(
    @NombreApellido VARCHAR(50),
    @Dni            INT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @ERRORES VARCHAR(MAX) = '';
    DECLARE @DniHash VARBINARY(32) = dbo.ufnHashDato(CONVERT(VARCHAR(20), @Dni));
 
    IF @NombreApellido IS NULL OR LTRIM(RTRIM(@NombreApellido)) = ''
        SET @ERRORES += 'El nombre y apellido no pueden estar vacios.' + CHAR(13) + CHAR(10);
 
    IF @Dni < 1
        SET @ERRORES += 'El DNI debe ser un numero positivo.' + CHAR(13) + CHAR(10);
 
    IF EXISTS (SELECT 1 FROM Ventas.Visitante WHERE DniHash = @DniHash)
        SET @ERRORES += 'Ya existe un visitante registrado con ese DNI.' + CHAR(13) + CHAR(10);
 
    IF @ERRORES <> ''
        THROW 50001, @ERRORES, 1;
 
    OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE Cert_DatosSensibles;
 
    INSERT INTO Ventas.Visitante (NombreApellido, Dni, DniHash)
    VALUES (@NombreApellido, dbo.ufnEncriptar(CONVERT(VARCHAR(20), @Dni)), @DniHash);
 
    CLOSE SYMMETRIC KEY SK_DatosSensibles;
 
    SELECT SCOPE_IDENTITY() AS IdCreado;
END
GO
 
-- ----------------------------------------------------------------
-- 4.6) Ventas.uspVisitanteModificar
-- ----------------------------------------------------------------
CREATE OR ALTER PROCEDURE Ventas.uspVisitanteModificar(
    @VisitanteId    INT,
    @NombreApellido VARCHAR(50),
    @Dni            INT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @ERRORES VARCHAR(MAX) = '';
    DECLARE @DniHash VARBINARY(32) = dbo.ufnHashDato(CONVERT(VARCHAR(20), @Dni));
 
    IF NOT EXISTS (SELECT 1 FROM Ventas.Visitante WHERE VisitanteId = @VisitanteId)
        SET @ERRORES += 'El visitante que se quiere modificar no existe.' + CHAR(13) + CHAR(10);
 
    IF @NombreApellido IS NULL OR LTRIM(RTRIM(@NombreApellido)) = ''
        SET @ERRORES += 'El nombre y apellido no pueden estar vacios.' + CHAR(13) + CHAR(10);
 
    IF @Dni < 1
        SET @ERRORES += 'El DNI debe ser un numero positivo.' + CHAR(13) + CHAR(10);
 
    IF EXISTS (SELECT 1 FROM Ventas.Visitante WHERE DniHash = @DniHash AND VisitanteId <> @VisitanteId)
        SET @ERRORES += 'El DNI ingresado pertenece a otro visitante.' + CHAR(13) + CHAR(10);
 
    IF @ERRORES <> ''
        THROW 50001, @ERRORES, 1;
 
    OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE Cert_DatosSensibles;
 
    UPDATE Ventas.Visitante
    SET NombreApellido = @NombreApellido,
        Dni             = dbo.ufnEncriptar(CONVERT(VARCHAR(20), @Dni)),
        DniHash         = @DniHash
    WHERE VisitanteId = @VisitanteId;
 
    CLOSE SYMMETRIC KEY SK_DatosSensibles;
END
GO