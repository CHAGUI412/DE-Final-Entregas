# Respuestas

## 1. ¿Por qué se pudo consultar el tercer día sin registrar una partición nueva?

Porque la tabla usa partition projection. En vez de guardar en Glue una fila por cada partición (que es lo que se hace con un crawler o con `ALTER TABLE ADD PARTITION`), Glue solo guarda unas reglas: la columna `fecha` es de tipo date, el formato es `yyyy-MM-dd`, el rango va de `2026-10-01` a `2026-10-03` con intervalo de 1 día, y la plantilla de ubicación es `s3://<bucket>/entregas/fecha=${fecha}/`. Cuando Athena recibe una consulta, con esas reglas calcula las fechas del rango y arma la ruta de cada una en ese momento.

El día 3 ya estaba dentro del rango desde el despliegue inicial, pero no tenía ningún archivo en S3, así que en la etapa inicial la tabla solo devolvía 12 registros (días 1 y 2). Cuando subí `fecha=2026-10-03/entregas.csv` a la ruta que describe la plantilla, Athena lo encontró solo y la tabla pasó a 18 registros, sin tocar Terraform, sin crawler, sin `MSCK REPAIR TABLE` y sin `ADD PARTITION`. Esto se ve en la evidencia comparando las ejecuciones de la etapa `inicial` con las de la etapa `final` en `evidencias/ejecuciones_athena.csv`, y en `resultados/final/verificacion_total_tabla.csv`, que muestra los 18 registros.

## 2. Si se subiera un archivo para el 4 de octubre manteniendo la configuración actual, ¿qué resultado se esperaría y qué se debería modificar para incluirlo?

No pasaría nada visible: la consulta no daría error, pero tampoco devolvería esas filas. El 4 de octubre queda fuera del rango proyectado (`2026-10-01,2026-10-03`), entonces Athena nunca genera esa partición ni busca en esa ruta, aunque el archivo exista en S3. La proyección no mira qué hay en el bucket, solo calcula las fechas del rango. Por eso la tabla seguiría con 18 registros y los agregados no incluirían el día 4.

Para incluirlo hay que cambiar la propiedad `projection.fecha.range` de la tabla, o sea la variable `fecha_fin` en Terraform, a `2026-10-04`, y volver a hacer `terraform apply`. Eso solo actualiza los metadatos de la tabla en Glue, no hay que mover ningún dato. Si se quiere que los días nuevos entren siempre sin tocar nada, el rango también acepta `NOW` como límite final (por ejemplo `2026-10-01,NOW`).
