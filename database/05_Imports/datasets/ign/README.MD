# Áreas Protegidas — Instituto Geográfico Nacional (IGN)

**Fuente:** Instituto Geográfico Nacional (IGN) — Capa oficial SIG `área_protegida`.

**Propósito en el sistema:** provee la geolocalización de referencia para parques ya existentes. Actualiza `Latitud` y `Longitud` en `Parques.Parque` con el centroide calculado a partir del bounding box del polígono oficial.

**Formato:** GeoJSON (FeatureCollection) — 506 features, geometría `MultiPolygon`.

**Contenido:** todas las áreas protegidas del territorio argentino, de todas las jurisdicciones (nacional, provincial, municipal). No todas existen en el sistema; el SP solo actualiza parques ya cargados por la fuente INDEC/APN.

| Propiedad GeoJSON | Uso                                              |
|-------------------|--------------------------------------------------|
| `fna`             | Nombre completo — usado para matching con `Parques.Parque.Nombre` |
| `gna`             | Tipo genérico del área (referencia, no importado) |
| `nam`             | Nombre corto (referencia)                        |
| `bbox`            | `[lon_min, lat_min, lon_max, lat_max]` — centroide: promedio de cada par |

**Coordenada de referencia:** centroide del `bbox`, no del polígono real. No representa el acceso ni la sede administrativa.

**Nota sobre encoding:** el archivo está en UTF-8. En servidores SQL Server con collation Latin1, los caracteres con tilde pueden no leerse correctamente. En ese caso, convertir el archivo a ANSI antes de importar o cargar las excepciones en `Importacion.EquivalenciaNombreFuente`.

**Descarga:** https://www.ign.gob.ar/NuestrasActividades/InformacionGeoespacial/CapasSIG

**SP de importación:** `Parques.uspImportarUbicacionesDeAreasProtegidas`
