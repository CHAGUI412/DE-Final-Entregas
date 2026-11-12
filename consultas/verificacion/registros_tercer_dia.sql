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
