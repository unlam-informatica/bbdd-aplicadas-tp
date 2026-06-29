# Trabajo Práctico: Sistema de Gestión para Parques Nacionales

**Datos Generales**

- **Asignatura:** 3641 – Bases de Datos Aplicada.
- **Objetivo:** Que el alumno demuestre su comprensión de los conceptos vertidos a lo largo de la materia en un escenario real de aplicación.

---

## I. Pautas Generales y Metodología

Las siguientes pautas administrativas se mantienen idénticas al estándar de la cátedra:

- **Repositorio:** Cada grupo utilizará un repositorio en GitHub, invitando al docente que se le asigne desde el inicio. Es VITAL que todos los cambios se registren allí. Todos los miembros del grupo deben demostrar participación en el repositorio para aprobar el trabajo. El repositorio debe ser público.

- **IMPORTANTE:** No expongan datos privados en ningún archivo en el repositorio.

- Se espera que sea el mismo grupo el que investigue las particularidades del negocio para el que se debe modelar el sistema. Pueden utilizar medios electrónicos o entrevistas personales para determinar el comportamiento del sistema. Cuando el comportamiento modelado no tenga sentido o carezca de lógica el punto afectado se considerará inválido.

- **Formato de Archivos:** Los documentos deben ser PDF. El nombre del archivo final debe seguir el formato "ComXXXX_GrupoYY" (ej: Com2900_Grupo08). Cuando se trate de archivos inviduales en lugar de Grupo deberá decir APELLIDO_NOMBRE del alumno.

- **Código Fuente:**
  - Todo el código debe estar incluido en una solución en MS SQL Server Management Studio.
  - Los scripts deben validar existencia de objetos antes de crear/borrar. No use SQL dinámico a menos que sea absolutamente necesario.
  - Deben incluirse scripts de testing con comentarios sobre el resultado esperado. Los scripts de testing se deben generar por separado de los de creación de objetos.
  - Generen un script para crear todas las tablas, otro para crear los SP, otro para las vistas, funciones. Por separado deben existir los scripts de testing, que deben incluir en comentarios las indicaciones sobre el resultado esperado de la ejecución de cada prueba. Asegúrense de que las validaciones se prueben con los mismos.
  - Los scripts de importación deben generarse por separado de los demás.
  - Norma de Nomenclatura: Deben definir y documentar una norma para nombres de tablas, SPs y variables. Esto debe incluirse en el documento a presentar.
  - Todos los scripts deben comenzar con un comentario donde se consigne el nombre de la universidad, de la materia, los componentes del grupo y el objetivo del código que se encuentra a continuación.

---

## II. El Proyecto: Sistema de Gestión de Parques Nacionales

### 1. Introducción

La Administración de Parques Nacionales requiere un sistema centralizado para gestionar la operación de múltiples parques distribuidos en el territorio nacional.

Actualmente, gran parte de la información se maneja de forma descentralizada o manual, lo que genera dificultades en el control de ingresos, gestión de servicios turísticos, supervisión de concesiones y administración del personal.

El objetivo es diseñar un sistema que permita integrar toda esta información, mejorar la trazabilidad y facilitar la toma de decisiones.

### 2. Alcance

**Actual (AS-IS)**

- Cada parque gestiona de manera independiente la venta de entradas.
- Las actividades turísticas (excursiones, visitas guiadas, etc.) no están unificadas ni sistematizadas.
- No existe un registro centralizado de concesiones comerciales.
- El padrón de guardaparques y guías autorizados se encuentra disperso o desactualizado.
- La información pública disponible sobre parques no está integrada al sistema.

**To BE (El Sistema Solicitado)**

**El sistema debe centralizar la gestión de todos los parques nacionales, contemplando los siguientes módulos:**

**A. Gestión de Parques**

- **Cada parque debe registrarse con:**
  - Nombre
  - Ubicación
  - Superficie
  - Tipo (reserva, parque nacional, monumento natural, etc.)
- Debe poder consultarse información general y operativa de cada parque.
- El sistema debe permitir la importación de datos públicos oficiales para mantener actualizada la información de los parques.

**B. Venta de Entradas**

- Cada parque debe registrar la venta de entradas.
- Las entradas pueden diferenciarse por:
  - Tipo de visitante (residente, extranjero, estudiante, jubilado, etc.)
  - Fecha de acceso
  - Parque visitado
- Se debe permitir:
  - Registrar ventas individuales
  - Registrar ventas masivas
  - Actualizar precios de forma independiente en cada parque
- Debe mantenerse historial de ventas.
- Las ventas deben registrarse con la información pertinente a un ticket factura (punto de venta, número, item, precio, total, forma de pago, etc).

**C. Gestión de Atracciones y Tours**

- Cada parque puede ofrecer:
  - Atracciones gratuitas
  - Atracciones pagas
  - Tours guiados
- Para cada actividad se debe registrar:
  - Nombre
  - Tipo
  - Costo (si aplica)
  - Duración
  - Cupo máximo
- Los tours pueden estar asociados a guías autorizados.
- Debe registrarse la contratación de estos servicios por parte de visitantes.
  - Puede hacerse en la misma transacción (ticket) que la venta de entradas o por separado.

**D. Gestión de Concesiones**

- El sistema debe registrar concesiones otorgadas dentro de los parques:
  - Comercios (restaurantes, tiendas, etc.)
  - Empresas de turismo
- Para cada concesión se debe almacenar:
  - Empresa concesionaria
  - Tipo de actividad
  - Parque donde opera
  - Fecha de inicio y fin de contrato
  - Monto del alquiler o canon mensual que se debe abonar.
  - Registro de los pagos del canon.
- Debe poder consultarse el estado de cada concesión
  - Próximas a vencer
  - Atrasadas con los pagos

**E. Gestión de Personal**

Guardaparques

- Registro completo de guardaparques:
  - Datos personales
  - Parque asignado
  - Fecha de ingreso/egreso. Motivo de egreso si corresponde.
- Un guardaparque pertenece a un único parque. Pero puede ser reasignado.
  - Debe ser posible consultar si está activo o no y todos los parques donde haya trabajado detallando los períodos en que lo hizo.

Guías Autorizados

- Registro de guías habilitados:
  - Datos personales
  - Habilitaciones
  - Título con el que ejerce (si posee)
  - Especialidad
- Debe registrarse:
  - Qué guía participa en cada tour
  - Vigencia de su autorización

**F. Importación de Datos Externos**

El sistema debe permitir importar información desde archivos públicos (CSV/Excel), tales como:

- Información oficial de parques nacionales
- Estadísticas de visitantes
- Datos turísticos abiertos
- Registros públicos de guías habilitados

Requisitos:

- Implementar lógica de Upsert (insert/update).
- Evitar duplicados en importaciones reiteradas del mismo dataset.
- Manejar errores de formato o datos incompletos.
- Permitir importar parcialmente los registros válidos.

**Seleccionen al menos tres datasets en al menos dos formatos distintos (CSV, XML, etc) de los siguientes sitios o de otros de índole gubernamental o de ONGs:**

https://www.untourism.int/

https://www.protectedplanet.net/en

https://www.ign.gob.ar/

https://datos.gob.ar/

https://datos.yvera.gob.ar/

**Deberán asimismo consumir al menos dos APIs, por ejemplo:**

- Para calcular el monto al momento de cobrar entradas u otros ítems en moneda extranjera.
- Determinar si las condiciones climáticas son favorables (por ejemplo podrían registrar jornadas lluviosas para indicarlo en informes sobre venta de entradas).
- Consulta de feriados para cálculo de valor de entradas.
- Para consultar información on line relacionada.

Respecto a ambos: investigue y documente las fuentes de datos y API que escojan.

**G. Proyección y Análisis**

- Generar reportes sobre:
  - Cantidad de visitantes por parque
  - Ingresos por entradas y actividades
  - Actividades más demandadas

Valiéndose de las APIs que haya vinculado puede además mostrar los ingresos en moneda extranjera, impacto de factores climáticos en venta de entradas, concurrencia en días feriados, etc.

Presente estos reportes en alguna plataforma de BI (open source o gratuita) que ejecute localmente o en la nube. Los datos deben provenir de la base SQL, sea que pueda conectarlo directamente como fuente de datos (óptimo) o exportar-importar en el software de BI.

---

## III. Entregas y Hitos

El trabajo práctico es de carácter evaluativo. Deberán generar un documento en formato PDF (para las entregas 3 en adelante) con las explicaciones y documentación necesarias. En la carátula debe figurar la fecha de entrega y los miembros del grupo que efectivamente participaron.

El trabajo se divide en las siguientes etapas. Cada etapa se corrige como aprobada o desaprobada.

**Entrega 1: Informe de investigación y costos On-Premise.**

- Se le asignará un DBMS para investigar.
- Presentar requisitos técnicos (Hardware, Licenciamiento, etc.)
- Fundamente todas sus recomendaciones, sean favorables o no.
- En caso de que no recomiende emplear el motor que se le asignó: proponga un DBMS alternativo que se ajuste al proyecto y realice el análisis para el mismo.
  - Incluya una propuesta de un proyecto secundario relacionado en el que podría emplearse el DBMS descartado.
- Proponga los recursos humanos necesarios para el proyecto: perfil, seniority, dedicación, plazo de contrato.
  - Incluya los costos para los RRHH.

**Entrega 2: Informe de investigación y costos Cloud**

- Calcular costos fijos y de inversión inicial para alojar la DB en Azure, AWS y Google Cloud. Puede emplear otros servicios de nube si lo ve conveniente.
  - Si en la entrega 1 optó por NO recomendar el DBMS asignado deberá realizar el análisis para un motor alternativo. El docente que corrija la entrega 1 le indicará si puede usar el mismo que propuso u otro.
- **Comparativa Cloud:** Justificar la elección (IaaS vs PaaS vs SaaS) y presentar conclusiones como si fuera para el cliente.
- **Comparativa Cloud vs On-Premise**: Presente una comparación de costos de implementación en la nube y on premise, con la recomendación de elección y argumentos que lo respalden.

Pautas generales aplicables a las entregas 1 y 2

- **Metodología:** La entrega será INDIVIDUAL.
- **Escenario:** Se estima que la base de datos acumulará 1 GB en los primeros dos años y requiere alta disponibilidad.
- **Todos los costos fijos deben presentarse anualizados y en dólares.** Incluyan los perfiles de recursos humanos requeridos, la duración del contrato, la justificación para los mismos, y el costo de la remuneración correspondiente.
- Presente un informe de inversión donde consten los desembolsos que se harían por única vez y los que deben hacerse anualmente.
- **Deberá respaldar con fuentes verificables online todos los datos presentados.**
  - En caso de que no cuente con cierta información (por ejemplo, datos de salarios en Argentina para cierto DBMS con un perfil específico) puede emplear información de otros países o de otro DBMS similar, aclarar y fundamentar la elección realizada.
  - Los sitios o fuentes de información que utilice deben ser verificables (no alcanza con citar una IA o un sitio sin respaldo).
- **Deberán armar una presentación comercial (formato powerpoint o PDF) para cada entrega con un mínimo de 5 y un máximo de 10 páginas incluyendo la carátula.** La presentación deberá estar orientada al cliente, experto en su rubro pero no en informática. No es una presentación académica.
- **Deberá grabar un video de un máximo de 5 minutos** donde utilice la presentación comercial para plantear la viabilidad (o no) de la solución.
  - En caso de que haya propuesto emplear otro DBMS, incluya la fundamentación y el análisis del mismo.
- **El video deberá subirlo a OneDrive.** La pauta de duración máxima es crítica: si la duración del video es mayor a 5 minutos se considerará desaprobado.
- **Asegúrese de que la calidad de audio sea suficiente para que se comprenda claramente su explicación.** Si lo desea puede grabarlo superponiendo su propia imagen (cámara), pero no es obligatorio.

**Entrega 3: Diagrama de Entidad Relación (DER)**

- Debe presentarse en formato imagen (JPG/PNG) insertado en el documento. Debe ser legible.
- Analice la totalidad del enunciado para determinar la estructura de la base de datos que propondrá. Se espera que aplique las tres primeras FN, y en los casos donde decida no hacerlo lo justifique.
- El tipo de DER y el nivel de detalle se dejan a criterio del grupo. Deben constar mínimamente las relaciones y la cardinalidad de estas.
- Si en las entregas posteriores se realizan cambios en la estructura planteada, deberán documentar los cambios con un breve párrafo que enuncie los cambios y su justificación, así como las nuevas versiones del DER.

**Entrega 4: Instalación y Configuración**

- Documento técnico detallando la instalación del motor SQL Server elegido, configuraciones de memoria, seguridad y ubicación de archivos. Este documento está dirigido a un administrador de bases de datos. No incluya capturas de pantalla.

**Entrega 5: Base de Datos**

Deberán entregar en una solución de SSMS scripts bajo esta pauta:

- Generación de la base de datos y esquemas
- Generación de tablas y restricciones. Un script para todas las tablas como mínimo.
- Generación de procedimientos almacenados para el manejo de los datos de cada tabla. Ninguna operación de alta, baja o modificación debe requerir el acceso directo a la tabla. Todas deben estar encapsuladas en store procedures preparados a tal fin. Un script para los SP de operaciones ABM como mínimo.
- Los procedimientos almacenados deben realizar validaciones (un mínimo de 10 condiciones entre todas las tablas, a su elección) e informar con claridad cuando no sean cumplidas. Presente mensajes de error claros para un usuario final, en el caso de las validaciones presente un solo mensaje con todas las condiciones no cumplidas (en un mismo SP y operación).
- No utilice SQL dinámico a menos que sea estrictamente necesario.
- No se admitirá el uso de scripts o software por fuera del motor SQL Server, tampoco CLR. Todo deberá codificarse en TSQL.
- Deben generar además procedimientos que sigan la lógica de negocio. Por ejemplo, para la registración de ventas, ingreso de stock, ajustes de precios, etc. Estas operaciones afectarían varias tablas, por lo que deben existir procedimientos que manejen las mismas aplicando transacciones que garanticen la integridad de los datos. Estos SP deben indicarse en scripts separados.
- Todos los scripts de generación de SPs deben estar acompañados (en relación 1:1) de scripts de testing que permitan validar el correcto funcionamiento de los mismos. Deben presentar scripts de testing exitosos, acompañados de evidencia de los datos manipulados (querys). También scripts de testing que demuestren el comportamiento de las validaciones cuando no se las cumple.
- Cada script debe incluir comentarios al inicio donde se consigne fecha, nombre de los integrantes del grupo y una breve descripción del contenido.

Se espera lógica de negocio para:

- Venta de entradas
- Registro de actividades
- Asignación de guías
- Gestión de concesiones
- Importación de datos externos

**Entrega 6: Procesos de Importación**

- **Objetivo**: Importar información masiva a la base de datos mediante Stored Procedures (SP).
- **Archivos de Entrada:** Se deben procesar los archivos CSV o Excel tal cual se proveen (ver punto F de sección II). Durante la defensa del TP deberán descargar un archivo e importarlo en el momento.
- **Requisito:** Los SP deben manejar la lógica de "Upsert" (Insertar si es nuevo, Actualizar si existe) y no generar duplicados. No es necesario que lo implementen con la sentencia *merge*. Ahora bien, cuando se trate de información histórica deben asegurarse de que se mantenga el registro.
- **Transformación:** Si el archivo trae precios en una moneda distinta la transformación debe hacerse en T-SQL dentro del SP. Pueden valerse de objetos auxiliares (otro SP, una API, etc) para esas conversiones.
- **Validaciones:** al importar archivos externos es habitual hallar errores porque se modificó la estructura, faltan datos, etc. El mecanismo de importación debe ser lo suficientemente robusto para permitir la importación de los registros correctos y reportar los errores que impiden el procesamiento de otros. El nombre del archivo debe ser un parámetro dentro del módulo que emplee para la importación.
- **Los archivos no pueden modificarse con herramientas externas antes de importarse.**

**Entrega 7:  Reportes**

Deben generar los correspondientes Store Procedures para los siguientes reportes (al menos dos deben retornar XML; no se espera que el script genere el XML en el filesystem, basta que lo muestre cuando se ejecuta):

1. **Reporte de visitas por semana, mes y año, por parque**.
2. **Ingresos por parque por semana, mes y año:** Sumar total de entradas e ingresos por ese concepto, así como por tours adicionales y concesiones cobradas.
3. **Deudores:** Concesiones atrasadas en los pagos, detallando meses y montos.
4. **Matriz de visitas:** Tabla cruzada (Pivot) mostrando visitas por mes y parque.
5. **Parques y concesiones:** Listado de parques y vector anidado con concesiones (fecha de inicio, titular, servicio prestado, etc.).

**Entrega 8: Seguridad y Respaldo**

- **Cifrado:** Aplicar cifrado a datos sensibles (deberán determinar cuáles son). Esto debe aplicarse como un script de modificación sobre los datos y componentes del sistema existentes afectados (consultas, store procedures, tablas, etc.).
- **Roles:** Crear roles de seguridad (ej: admin, importador de datos, consultas) con permisos granulares. Documente los roles en un cuadro indicando los permisos que tiene cada uno.
- **Backup:** Definir y documentar una política de respaldo (RPO).
- El cifrado y los roles deberán implementarlo con código (SPs). Respecto a los backups deberán presentar la política en un documento sencillo.

**Entrega 9:**

1. **Repase los puntos del alcance (sección 2 "***to be***").** Asegúrese de incluir las consultas necesarias para cumplimentar esa sección.
2. **Incorpore una plataforma BI (puede ser PowerBI, Metabase, etc.)** y presente alguno de los reportes de la entrega 7.
   - Puede además mostrar un mapa con la ubicación de los parques valiéndose de los datos de geolocalización (latitud y longitud) que incorpore en la DB.
   - Genere al menos dos gráficos (barras, líneas, tortas, etc.) representativos para alguno de los reportes solicitados u otros que considere de utilidad.
3. Genere una **aplicación sencilla** en un lenguaje de su elección con la que pueda gestionar al menos las operaciones ABM en una de las tablas.
   1. Pueden también presentar una pantalla de importación de archivos que emplee la lógica de la entrega 6 y mostrar algun reporte de la entrega 7 (mínimamente guardar el XML).

---

## IV. Criterios de Aceptación (Juego de Datos)

Para dar por aprobado el desarrollo, el grupo debe entregar scripts de carga (seed data) que generen:

- Al menos 10 parques (además de los que pudieran importar).
- Al menos:
  - 30 actividades/tours
  - 20 guías
  - 20 guardaparques
  - 10 concesiones
- Historial de ventas de entradas

**Casos obligatorios:**

- Un parque con múltiples actividades simultáneas
- Un tour con cupo completo
- Registro de concesión vigente y vencida
- Importación con errores parciales

---

## V. Organización y Coloquio

- Las entregas pueden acompañarse de coloquios.
- Todos los integrantes del grupo deben estar conectados a la reunión por videoconferencia en el momento del coloquio. La ausencia por parte de un alumno implicará la desaprobación del trabajo. En todos los casos el coloquio se realizará en el horario de clase.
- En el coloquio, deberán ejecutar los scripts en vivo. Se solicitará eliminar la DB al inicio para probar la recreación completa desde cero.
- Uno de los miembros del grupo deberá compartir pantalla y realizar los pasos que solicite el docente para mostrar el trabajo.
- Es condición necesaria que todos los miembros expongan o respondan preguntas para aprobar la cursada de forma individual.
- Es necesario que todos los miembros del grupo dejen evidencia en el repositorio de su participación en el desarrollo del software. Si un miembro participó con menos de un 20% de líneas de código que el miembro del grupo que más código fuente generó, se considerará que no aportó a la solución y será desaprobado.
- Todos los integrantes del grupo deberán tener aprobadas las primeras dos entregas individuales del TP para poder presentar la parte grupal.
- No se permitirá el cambio de integrantes o fusión de grupos. Si uno de los miembros del grupo no participa, los demás miembros podrán informar la situación al docente para que el alumno en cuestión quede desafectado del grupo, debiendo preparar la totalidad del trabajo por su cuenta.
