#!/usr/bin/env bash
# Compara los resultados obtenidos en Athena con las referencias suministradas
cd "$(dirname "$0")/.."

comparar() {
  if diff -q "$1" "$2" > /dev/null; then
    echo "OK    $1"
  else
    echo "DIFF  $1 vs $2"
    diff "$1" "$2"
  fi
}

comparar resultados/inicial/intentos_por_fecha_estado.csv            resultados_esperados/intentos_por_fecha_estado_inicial.csv
comparar resultados/inicial/porcentaje_exito_por_fecha_ciudad.csv    resultados_esperados/porcentaje_exito_por_fecha_ciudad_inicial.csv
comparar resultados/inicial/duracion_promedio_2026-10-02.csv         resultados_esperados/duracion_promedio_2026-10-02.csv
comparar resultados/final/intentos_por_fecha_estado.csv              resultados_esperados/intentos_por_fecha_estado_final.csv
comparar resultados/final/porcentaje_exito_por_fecha_ciudad.csv      resultados_esperados/porcentaje_exito_por_fecha_ciudad_final.csv
