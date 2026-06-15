/* ============================================================
Universidad Nacional de La Matanza
Bases de Datos Aplicada - 3641 - Comisión 2900
Grupo: [Nº 1]
Integrantes: 
     
     - Arenas Vlasco, Artin Leonel
 
     - Leguizamon Sarmiento, Juan Andrés
     
     - Rios, Marcos Adrían
     
     - Romano, Jorge Dario
Objetivo: Creacion inicial de tablas, indices y Constraints.
Fecha:    14 de Junio 2026
============================================================ */


-- ============================================================
--  ESQUEMA: PARQUES
-- ============================================================

-- ------------------------------------------------------------
--  TiposParque
-- ------------------------------------------------------------
DROP TABLE IF EXISTS PARQUES.TiposParque;
GO
CREATE TABLE PARQUES.TipoParque(
    ID INT,
    Descripcion VARCHAR(255) NOT NULL
);

ALTER TABLE PARQUES.TiposParque
    ADD CONSTRAINT PK_TiposParque PRIMARY KEY (ID_TipoParque);


-- ------------------------------------------------------------
--  Parques
-- ------------------------------------------------------------
DROP TABLE IF EXISTS PARQUES.Parques;
GO
CREATE TABLE PARQUES.Parques(
    ID INT,
    Nombre VARCHAR(100) NOT NULL,
    Ubicacion VARCHAR(255) NOT NULL,
    Superficie DECIMAL(18,2),
    UID_Externo VARCHAR(100),
    ID_TipoParque INT NOT NULL
);

ALTER TABLE PARQUES.Parques
    ADD CONSTRAINT PK_Parques PRIMARY KEY (ID);


-- ============================================================
--  ESQUEMA: VENTAS
-- ============================================================

-- ------------------------------------------------------------
--  Formas_Pago
-- ------------------------------------------------------------
DROP TABLE IF EXISTS VENTAS.Formas_Pago;
GO
CREATE TABLE VENTAS.Formas_Pago (
    ID INT NOT NULL,
    Descripcion VARCHAR(50) NULL
);

ALTER TABLE VENTAS.Formas_Pago
    ADD CONSTRAINT PK_Formas_Pago PRIMARY KEY (ID);
ALTER TABLE VENTAS.Formas_Pago
    ADD CONSTRAINT Unique_Formas_Pago UNIQUE (ID);

-- ------------------------------------------------------------
--  Tipos_Visitante
-- ------------------------------------------------------------
DROP TABLE IF EXISTS VENTAS.Tipos_Visitante;
GO
CREATE TABLE VENTAS.Tipos_Visitante (
    ID_TipoVisitante INT NOT NULL,
    Descripcion VARCHAR(50) NULL
);

ALTER TABLE VENTAS.Tipos_Visitante
    ADD CONSTRAINT PK_Tipos_Visitante PRIMARY KEY (ID_TipoVisitante);


-- ------------------------------------------------------------
--  VentaEntrada_Cabecera
-- ------------------------------------------------------------
DROP TABLE IF EXISTS VENTAS.VentaEntrada_Cabecera;
GO
CREATE TABLE VENTAS.VentaEntrada_Cabecera (
    ID_Venta INT NOT NULL,
    ID_Parque INT NULL,
    ID_FormaPago INT NULL,
    Punto_Venta INT NULL,
    Numero_Ticket BIGINT NULL,
    Fecha_Venta DATETIME NULL,
    Total_Facturado DECIMAL(19,4) NULL
);

ALTER TABLE VENTAS.VentaEntrada_Cabecera
    ADD CONSTRAINT PK_VentaEntrada_Cabecera PRIMARY KEY (ID_Venta);


-- ------------------------------------------------------------
--  VentaEntrada_Detalle
-- ------------------------------------------------------------
DROP TABLE IF EXISTS VENTAS.VentaEntrada_Detalle;
GO
CREATE TABLE VENTAS.VentaEntrada_Detalle (
    ID_Detalle INT NOT NULL,
    ID_Venta INT NULL,
    ID_Actividad INT NULL,
    ID_TipoVisitante INT NULL,
    Cantidad INT NULL,
    Precio_Unitario DECIMAL(19,4) NULL,
    Subtotal DECIMAL(19,4) NULL,
    Fecha_Actividad DATETIME NULL
);

ALTER TABLE VENTAS.VentaEntrada_Detalle
    ADD CONSTRAINT PK_VentaEntrada_Detalle PRIMARY KEY (ID_Detalle);


-- ============================================================
--  ESQUEMA: CONCESIONES
-- ============================================================

-- ------------------------------------------------------------
--  Concesiones
-- ------------------------------------------------------------
DROP TABLE IF EXISTS CONCESIONES.Concesiones;
GO
CREATE TABLE CONCESIONES.Concesiones (
    ID_Concesion INT NOT NULL,
    ID_Parque INT NULL,
    Empresa_Concesionaria VARCHAR(150) NULL,
    Tipo_Actividad VARCHAR(100) NULL,
    Fecha_Inicio DATE NULL,
    Fecha_Fin DATE NULL,
    Canon_Mensual DECIMAL(19,4) NULL,
    Activa BIT NULL
);

ALTER TABLE CONCESIONES.Concesiones
    ADD CONSTRAINT PK_Concesiones PRIMARY KEY (ID_Concesion);


-- ------------------------------------------------------------
--  Pagos_Canon
-- ------------------------------------------------------------
DROP TABLE IF EXISTS CONCESIONES.Pagos_Canon;
GO
CREATE TABLE CONCESIONES.Pagos_Canon (
    ID_Pago INT NOT NULL,
    ID_Concesion INT NULL,
    Fecha_Pago DATETIME NULL,
    Periodo_Mes INT NULL,
    Periodo_Anio INT NULL,
    Monto_Abonado DECIMAL(19,4) NULL
);

ALTER TABLE CONCESIONES.Pagos_Canon
    ADD CONSTRAINT PK_Pagos_Canon PRIMARY KEY (ID_Pago);


-- ============================================================
--  ESQUEMA: ACTIVIDADES
-- ============================================================

-- ------------------------------------------------------------
--  Actividades
-- ------------------------------------------------------------
DROP TABLE IF EXISTS Actividades.Actividades;
GO
CREATE TABLE ACTIVIDADES.Actividades (
    ID_Actividad INT NOT NULL,
    Nombre VARCHAR(100) NULL,
    Tipo VARCHAR(30) NULL,
    Duracion_Minutos INT NULL,
    Cupo_Maximo INT NULL
);

ALTER TABLE ACTIVIDADES.Actividades
    ADD CONSTRAINT PK_Actividades PRIMARY KEY (ID_Actividad);


-- ------------------------------------------------------------
--  Parque_Precio_Actividad
-- ------------------------------------------------------------
DROP TABLE IF EXISTS ACTIVIDADES.Parque_Precio_Actividad;
GO
CREATE TABLE ACTIVIDADES.Parque_Precio_Actividad (
    ID_Parque INT NOT NULL,
    ID_Actividad INT NOT NULL,
    Precio_Base DECIMAL(19,4) NULL
);

ALTER TABLE ACTIVIDADES.Parque_Precio_Actividad
    ADD CONSTRAINT PK_Parque_Precio_Actividad PRIMARY KEY (ID_Parque, ID_Actividad);


-- ------------------------------------------------------------
--  Horarios_Permitidos
-- ------------------------------------------------------------
DROP TABLE IF EXISTS ACTIVIDADES.Horarios_Permitidos;
GO
CREATE TABLE ACTIVIDADES.Horarios_Permitidos (
    ID_Horario INT NOT NULL,
    Nombre_Turno VARCHAR(30) NULL,
    Hora_Inicio TIME NOT NULL,
    Hora_Fin TIME NOT NULL
);

ALTER TABLE ACTIVIDADES.Horarios_Permitidos
    ADD CONSTRAINT PK_Horarios_Permitidos PRIMARY KEY (ID_Horario);


-- ------------------------------------------------------------
--  Tours_Guias
-- ------------------------------------------------------------
DROP TABLE IF EXISTS ACTIVIDADES.Tours_Guias;
GO
CREATE TABLE ACTIVIDADES.Tours_Guias (
    ID_Tour_Guia INT NOT NULL,
    ID_Parque INT NULL,
    ID_Actividad INT NULL,
    ID_Guia INT NULL,
    ID_Horario INT NULL
);

ALTER TABLE ACTIVIDADES.Tours_Guias
    ADD CONSTRAINT PK_Tours_Guias PRIMARY KEY (ID_Tour_Guia);


-- ============================================================
--  ESQUEMA: PERSONAL
-- ============================================================

-- ------------------------------------------------------------
--  Guardaparques
-- ------------------------------------------------------------
DROP TABLE IF EXISTS PERSONAL.Guardaparques;
GO
CREATE TABLE PERSONAL.Guardaparques (
    ID_Guardaparque INT NOT NULL,
    Nombre VARCHAR(100) NULL,
    Apellido VARCHAR(100) NULL,
    DNI INT NULL,
    Fecha_Ingreso_Sistema DATE NULL,
    Activo BIT NULL,
    ID_Parque_Actual INT NULL
);

ALTER TABLE PERSONAL.Guardaparques
    ADD CONSTRAINT PK_Guardaparques PRIMARY KEY (ID_Guardaparque);


-- ------------------------------------------------------------
--  Historial_Guardaparques
-- ------------------------------------------------------------
DROP TABLE IF EXISTS PERSONAL.Historial_Guardaparques;
GO
CREATE TABLE PERSONAL.Historial_Guardaparques (
    ID_Historial INT NOT NULL,
    ID_GuardaParque INT NULL,
    ID_Parque INT NULL,
    Fecha_Desde DATE NULL,
    Fecha_Hasta DATE NULL
);

ALTER TABLE PERSONAL.Historial_Guardaparques
    ADD CONSTRAINT PK_Historial_Guardaparques PRIMARY KEY (ID_Historial);


-- ------------------------------------------------------------
--  Guias
-- ------------------------------------------------------------
DROP TABLE IF EXISTS PERSONAL.Guias;
GO
CREATE TABLE PERSONAL.Guias (
    ID_Guia INT NOT NULL,
    Nombre VARCHAR(100) NULL,
    Apellido VARCHAR(100) NULL,
    DNI INT NULL,
    Titulo VARCHAR(100) NULL,
    Especialidad VARCHAR(100) NULL,
    Vigencia_Autorizacion DATE NULL
);

ALTER TABLE PERSONAL.Guias
    ADD CONSTRAINT PK_Guias PRIMARY KEY (ID_Guia);


-- ============================================================
--  FOREIGN KEYS
-- ============================================================

-- PARQUES.Parques
ALTER TABLE PARQUES.Parques
    ADD CONSTRAINT FK_Parques_TipoParque
        FOREIGN KEY (ID_TipoParque) REFERENCES PARQUES.TiposParque (ID_TipoParque);

-- PERSONAL.Guardaparques
ALTER TABLE PERSONAL.Guardaparques
    ADD CONSTRAINT FK_Guardaparques_ParqueActual
        FOREIGN KEY (ID_Parque_Actual) REFERENCES PARQUES.Parques (ID_Parque);

-- PERSONAL.Historial_Guardaparques
ALTER TABLE PERSONAL.Historial_Guardaparques
    ADD CONSTRAINT FK_Historial_Guardaparque
        FOREIGN KEY (ID_GuardaParque) REFERENCES PERSONAL.Guardaparques (ID_Guardaparque);

ALTER TABLE PERSONAL.Historial_Guardaparques
    ADD CONSTRAINT FK_Historial_Parque
        FOREIGN KEY (ID_Parque) REFERENCES PARQUES.Parques (ID_Parque);

-- ACTIVIDADES.Parque_Precio_Actividad
ALTER TABLE ACTIVIDADES.Parque_Precio_Actividad
    ADD CONSTRAINT FK_PPA_Parque
        FOREIGN KEY (ID_Parque) REFERENCES PARQUES.Parques (ID_Parque);

ALTER TABLE ACTIVIDADES.Parque_Precio_Actividad
    ADD CONSTRAINT FK_PPA_Actividad
        FOREIGN KEY (ID_Actividad) REFERENCES ACTIVIDADES.Actividades (ID_Actividad);

-- ACTIVIDADES.Tours_Guias
ALTER TABLE ACTIVIDADES.Tours_Guias
    ADD CONSTRAINT FK_ToursGuias_Parque
        FOREIGN KEY (ID_Parque) REFERENCES PARQUES.Parques (ID_Parque);

ALTER TABLE ACTIVIDADES.Tours_Guias
    ADD CONSTRAINT FK_ToursGuias_Actividad
        FOREIGN KEY (ID_Actividad) REFERENCES ACTIVIDADES.Actividades (ID_Actividad);

ALTER TABLE ACTIVIDADES.Tours_Guias
    ADD CONSTRAINT FK_ToursGuias_Guia
        FOREIGN KEY (ID_Guia) REFERENCES PERSONAL.Guias (ID_Guia);

ALTER TABLE ACTIVIDADES.Tours_Guias
    ADD CONSTRAINT FK_ToursGuias_Horario
        FOREIGN KEY (ID_Horario) REFERENCES ACTIVIDADES.Horarios_Permitidos (ID_Horario);

-- VENTAS.VentaEntrada_Cabecera
ALTER TABLE VENTAS.VentaEntrada_Cabecera
    ADD CONSTRAINT FK_VEC_Parque
        FOREIGN KEY (ID_Parque) REFERENCES PARQUES.Parques (ID_Parque);

ALTER TABLE VENTAS.VentaEntrada_Cabecera
    ADD CONSTRAINT FK_VEC_FormaPago
        FOREIGN KEY (ID_FormaPago) REFERENCES VENTAS.Formas_Pago (UniqueID);

-- VENTAS.VentaEntrada_Detalle
ALTER TABLE VENTAS.VentaEntrada_Detalle
    ADD CONSTRAINT FK_VED_Venta
        FOREIGN KEY (ID_Venta) REFERENCES VENTAS.VentaEntrada_Cabecera (ID_Venta);

ALTER TABLE VENTAS.VentaEntrada_Detalle
    ADD CONSTRAINT FK_VED_Actividad
        FOREIGN KEY (ID_Actividad) REFERENCES ACTIVIDADES.Actividades (ID_Actividad);

ALTER TABLE VENTAS.VentaEntrada_Detalle
    ADD CONSTRAINT FK_VED_TipoVisitante
        FOREIGN KEY (ID_TipoVisitante) REFERENCES VENTAS.Tipos_Visitante (ID_TipoVisitante);

-- CONCESIONES.Concesiones
ALTER TABLE CONCESIONES.Concesiones
    ADD CONSTRAINT FK_Concesiones_Parque
        FOREIGN KEY (ID_Parque) REFERENCES PARQUES.Parques (ID_Parque);

-- CONCESIONES.Pagos_Canon
ALTER TABLE CONCESIONES.Pagos_Canon
    ADD CONSTRAINT FK_PagosCanon_Concesion
        FOREIGN KEY (ID_Concesion) REFERENCES CONCESIONES.Concesiones (ID_Concesion);
