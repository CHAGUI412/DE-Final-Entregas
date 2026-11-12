#!/usr/bin/env bash
# Uso: bash scripts/ejecutar_consulta.sh <etapa> <archivo_sql> <archivo_resultado>
# Ejemplo:
#   bash scripts/ejecutar_consulta.sh inicial consultas/intentos_por_fecha_estado.sql resultados/inicial/intentos_por_fecha_estado.csv
#
# Ejecuta la consulta en Athena (workgroup del ejercicio), espera a que termine,
# baja el resultado a archivo_resultado y agrega la ejecucion a evidencias/ejecuciones_athena.csv
set -euo pipefail

ETAPA="$1"
SQL="$2"
RESULTADO="$3"

# siempre desde la raiz del repo
cd "$(dirname "$0")/.."

BUCKET=$(terraform -chdir=infraestructura output -raw bucket)
BASE=$(terraform -chdir=infraestructura output -raw base_datos)
WG=$(terraform -chdir=infraestructura output -raw workgroup)
REGION=$(terraform -chdir=infraestructura output -raw region)

ID=$(aws athena start-query-execution \
  --region "$REGION" \
  --work-group "$WG" \
  --query-execution-context "Database=$BASE" \
  --query-string "$(cat "$SQL")" \
  --query 'QueryExecutionId' --output text)

echo "Ejecucion $ID ($SQL)"

while true; do
  ESTADO=$(aws athena get-query-execution --region "$REGION" --query-execution-id "$ID" \
    --query 'QueryExecution.Status.State' --output text)
  case "$ESTADO" in
    SUCCEEDED) break ;;
    FAILED|CANCELLED)
      aws athena get-query-execution --region "$REGION" --query-execution-id "$ID" \
        --query 'QueryExecution.Status.StateChangeReason' --output text
      exit 1 ;;
    *) sleep 2 ;;
  esac
done

mkdir -p "$(dirname "$RESULTADO")"
# Athena escribe los valores entre comillas, se las quito para que quede igual a las referencias
aws s3 cp "s3://$BUCKET/resultados-athena/$ID.csv" - --region "$REGION" | sed 's/"//g' > "$RESULTADO"

mkdir -p evidencias
[ -f evidencias/ejecuciones_athena.csv ] || echo "etapa,archivo_sql,id_ejecucion,archivo_resultado" > evidencias/ejecuciones_athena.csv
echo "$ETAPA,$SQL,$ID,$RESULTADO" >> evidencias/ejecuciones_athena.csv

echo "Resultado guardado en $RESULTADO"
cat "$RESULTADO"
