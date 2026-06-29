# Catálogo de Áreas Protegidas — INDEC / APN

**Fuente:** Instituto Nacional de Estadística y Censos (INDEC) — Anuario Estadístico de la República Argentina 2024, dominio Ambiente. Datos provistos por la Administración de Parques Nacionales (APN).

**Propósito en el sistema:** fuente primaria del catálogo de parques. Crea y actualiza la entidad `Parques.Parque` con nombre oficial, localización, ecorregión, año de creación, superficie y descripción.

**Formato:** XLSX — hoja `030129`

**Contenido:** ~Áreas protegidas administradas por APN, incluyendo parques nacionales, reservas naturales, monumentos naturales, áreas marinas protegidas y reservas de la defensa.

| Columna (hoja) | Campo destino         | Notas                                          |
|----------------|-----------------------|------------------------------------------------|
| Nombre         | `Parques.Parque.Nombre`     | Se eliminan indicadores editoriales `(1)` `(2)` |
| Localización   | `Ubicacion`           | Puede incluir varias provincias                |
| Ecorregión     | `Ecorregion`          |                                                |
| Año de creación| `AnioCreacion`        | Se extrae solo el primer año cuando hay varios |
| Superficie (ha)| `Superficie`          | `///` indica monumento móvil → se guarda NULL  |
| Características| `Descripcion`         | Texto largo descriptivo                        |

**Páginas de descarga:**
- Anuario: https://anuario.indec.gob.ar/dominio03.html?dominio=Dominio+3&menu=Ambiente
- Archivo directo: https://anuario.indec.gob.ar/Condiciones%20y%20calidad%20ambientales/030129.xlsx

**SP de importación:** `Parques.uspImportarAreasProtegidas`
