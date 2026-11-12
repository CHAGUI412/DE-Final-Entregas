# Examen final: entregas con S3, Glue y Athena (partition projection)

Una tabla externa en Glue sobre CSV de entregas guardados en S3, consultada desde Athena. Las fechas se obtienen con partition projection, entonces un día nuevo se consulta con solo subir el archivo, sin crawlers ni `ADD PARTITION`.

```
CSV -> S3 (entregas/) -> Glue (tabla + projection) -> Athena -> S3 (resultados-athena/)
```

## Prerrequisitos

- Cuenta de AWS con permisos para S3, Glue y Athena
- AWS CLI v2 con credenciales configuradas (`aws configure`)
- Terraform >= 1.5
- Región usada: `us-east-1` (se cambia con la variable `region`)
- Bash (en Windows, la terminal de Ubuntu en WSL2)

Las credenciales y el estado de Terraform no se suben al repositorio (ver `.gitignore`).

Las credenciales se usan con el perfil `user_cli` (usuario IAM de la actividad de AWS). En cada terminal:

```bash
export AWS_PROFILE=user_cli
aws sts get-caller-identity   # debe mostrar .../user/user_cli
```

Ese usuario necesita permisos extra para el examen (crear el workgroup de Athena y vaciar el bucket). Están en `iam/politica_user_cli_examen_final.json`, que se agrega como una política administrada más y se adjunta a `user_cli`. El bucket se llama `de-aws-examen-entregas-<id de la cuenta>` para entrar en el filtro `de-aws-*` de los permisos de S3.

## Estructura

```
infraestructura/   principal.tf, variables.tf, salidas.tf
iam/               politica extra para user_cli
consultas/         SQL de las consultas y de la verificación del tercer día
resultados/        inicial/ y final/ (resultados obtenidos en Athena)
evidencias/        salidas de terraform, outputs y ejecuciones de Athena
scripts/           ejecutar_consulta.sh y comparar.sh
data/              CSV suministrados (no se modifican)
resultados_esperados/   referencias suministradas
respuestas.md
```

## 1. Despliegue

```bash
cd infraestructura
terraform init
terraform apply 2>&1 | tee ../evidencias/aplicacion_terraform.txt
terraform output -json > ../evidencias/outputs.json
cd ..
```

Se crean: bucket S3 privado (con bloqueo de acceso público), los prefijos `entregas/` y `resultados-athena/`, la base de datos de Glue `examen_entregas`, la tabla externa `entregas` con partition projection y el workgroup de Athena `examen-entregas`, cuyos resultados van a `resultados-athena/`.

El nombre del bucket es `de-aws-examen-entregas-<id de la cuenta>` para que sea único.

Propiedades de projection de la tabla (todas en `principal.tf`):

| Propiedad | Valor |
|---|---|
| `projection.enabled` | `true` |
| `projection.fecha.type` | `date` |
| `projection.fecha.format` | `yyyy-MM-dd` |
| `projection.fecha.range` | `2026-10-01,2026-10-03` |
| `projection.fecha.interval` / `.interval.unit` | `1` / `DAYS` |
| `storage.location.template` | `s3://<bucket>/entregas/fecha=${fecha}/` |

## 2. Carga inicial: días 1 y 2

Se suben solo estos dos archivos, uno por uno (sin `sync` ni `--recursive`). El día 3 se queda local.

```bash
BUCKET=$(terraform -chdir=infraestructura output -raw bucket)

aws s3 cp "data/entregas/fecha=2026-10-01/entregas.csv" "s3://$BUCKET/entregas/fecha=2026-10-01/entregas.csv"
aws s3 cp "data/entregas/fecha=2026-10-02/entregas.csv" "s3://$BUCKET/entregas/fecha=2026-10-02/entregas.csv"
```

## 3. Consultas iniciales

```bash
bash scripts/ejecutar_consulta.sh inicial consultas/intentos_por_fecha_estado.sql resultados/inicial/intentos_por_fecha_estado.csv
bash scripts/ejecutar_consulta.sh inicial consultas/porcentaje_exito_por_fecha_ciudad.sql resultados/inicial/porcentaje_exito_por_fecha_ciudad.csv
bash scripts/ejecutar_consulta.sh inicial consultas/duracion_promedio_2026-10-02.sql resultados/inicial/duracion_promedio_2026-10-02.csv
```

El script ejecuta la consulta en el workgroup del ejercicio, guarda el resultado en `resultados/inicial/` y agrega una fila a `evidencias/ejecuciones_athena.csv` (`etapa,archivo_sql,id_ejecucion,archivo_resultado`).

En este punto la tabla tiene 12 registros.

## 4. Nueva fecha: día 3

Sin tocar Terraform ni la tabla, solo se sube el archivo:

```bash
aws s3 cp "data/entregas/fecha=2026-10-03/entregas.csv" "s3://$BUCKET/entregas/fecha=2026-10-03/entregas.csv"
```

No se usa crawler, `MSCK REPAIR TABLE` ni `ALTER TABLE ADD PARTITION`. Luego se consulta:

```bash
# verificación: los 6 registros del día 3, sus conteos por estado y el total de la tabla (18)
bash scripts/ejecutar_consulta.sh final consultas/verificacion/registros_tercer_dia.sql resultados/final/verificacion_tercer_dia.csv
bash scripts/ejecutar_consulta.sh final consultas/verificacion/conteo_estados_tercer_dia.sql resultados/final/verificacion_conteo_estados_tercer_dia.csv
bash scripts/ejecutar_consulta.sh final consultas/verificacion/total_tabla.sql resultados/final/verificacion_total_tabla.csv

# las dos consultas agregadas otra vez, ahora con los tres días
bash scripts/ejecutar_consulta.sh final consultas/intentos_por_fecha_estado.sql resultados/final/intentos_por_fecha_estado.csv
bash scripts/ejecutar_consulta.sh final consultas/porcentaje_exito_por_fecha_ciudad.sql resultados/final/porcentaje_exito_por_fecha_ciudad.csv
```

`consultas/verificacion_tercer_dia.sql` reúne las tres consultas de verificación en un solo archivo; cada una se ejecuta desde su propio archivo en `consultas/verificacion/` porque Athena corre una consulta por vez y cada una devuelve columnas distintas.

## 5. Comparar con las referencias

```bash
bash scripts/comparar.sh
```

Compara cada resultado de `resultados/` con su archivo en `resultados_esperados/`. Todas las líneas deben salir en `OK`.

## 6. Limpieza

Primero se guardan las evidencias y se hace commit. Después:

```bash
BUCKET=$(terraform -chdir=infraestructura output -raw bucket)
aws s3 rm "s3://$BUCKET" --recursive          # vacía datos y resultados de Athena
cd infraestructura
terraform destroy 2>&1 | tee ../evidencias/eliminacion_terraform.txt
```

El bucket y el workgroup tienen `force_destroy = true`, así que `terraform destroy` también funciona si quedan objetos adentro.

## Respuestas conceptuales

Están en [`respuestas.md`](respuestas.md).
