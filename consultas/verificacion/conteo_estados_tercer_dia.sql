SELECT
    fecha,
    estado,
    COUNT(*) AS total_intentos
FROM examen_entregas.entregas
WHERE fecha = '2026-10-03'
GROUP BY fecha, estado
ORDER BY estado;
