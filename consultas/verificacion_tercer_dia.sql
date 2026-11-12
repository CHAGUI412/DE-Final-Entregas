-- Verificacion del tercer dia (2026-10-03).
-- Son tres consultas, cada una guardada tambien en su propio archivo dentro de
-- consultas/verificacion/ porque Athena ejecuta una consulta por vez y cada una
-- devuelve columnas distintas.

-- 1. Los seis registros del tercer dia  ->  resultados/final/verificacion_tercer_dia.csv
SELECT
    id_envio,
    ciudad,
    transportadora,
    estado,
    duracion_minutos,
    fecha
FROM examen_entregas.entregas
WHERE fecha = '2026-10-03'
ORDER BY id_envio;

-- 2. Conteo por estado del tercer dia  ->  resultados/final/verificacion_conteo_estados_tercer_dia.csv
SELECT
    fecha,
    estado,
    COUNT(*) AS total_intentos
FROM examen_entregas.entregas
WHERE fecha = '2026-10-03'
GROUP BY fecha, estado
ORDER BY estado;

-- 3. Total de registros de la tabla (debe ser 18)  ->  resultados/final/verificacion_total_tabla.csv
SELECT COUNT(*) AS total_registros
FROM examen_entregas.entregas;
