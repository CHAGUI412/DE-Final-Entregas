SELECT
    fecha,
    CAST(ROUND(AVG(duracion_minutos), 2) AS DECIMAL(6, 2)) AS duracion_promedio_minutos
FROM examen_entregas.entregas
WHERE fecha = '2026-10-02'
  AND estado = 'entregado'
GROUP BY fecha;
