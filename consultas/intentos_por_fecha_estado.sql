SELECT
    fecha,
    estado,
    COUNT(*) AS total_intentos
FROM examen_entregas.entregas
GROUP BY fecha, estado
ORDER BY fecha ASC, estado ASC;
