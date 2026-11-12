SELECT
    fecha,
    ciudad,
    CAST(ROUND(100.0 * COUNT_IF(estado = 'entregado') / COUNT(*), 2) AS DECIMAL(5, 2)) AS porcentaje_exito
FROM examen_entregas.entregas
GROUP BY fecha, ciudad
ORDER BY fecha ASC, ciudad ASC;
