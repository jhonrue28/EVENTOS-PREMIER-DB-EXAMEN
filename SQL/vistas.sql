-- ============================================================================
-- MÓDULO: Vistas y Consultas de Negocio
-- OBJETIVO: Generar reportes estratégicos para administración.
-- ============================================================================

USE eventos_premier;

-- ----------------------------------------------------------------------------
-- Vista: vista_resumen_reservas
-- Consolida la información visible de las reservas omitiendo IDs técnicos.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vista_resumen_reservas AS
SELECT 
    r.reserva_id,
    c.nombre_completo AS cliente,
    s.nombre AS salon,
    r.fecha_inicio,
    r.fecha_fin,
    r.valor_total,
    r.estado_reserva AS estado
FROM reservas r
INNER JOIN clientes c ON r.cliente_id = c.cliente_id
INNER JOIN salones s ON r.salon_id = s.salon_id;


-- ----------------------------------------------------------------------------
-- CONSULTAS REQUERIDAS
-- ----------------------------------------------------------------------------

-- Consulta 1: Reservas dentro de un rango de fechas específico
SELECT * 
FROM reservas 
WHERE fecha_inicio BETWEEN '2026-09-01 00:00:00' AND '2026-09-30 23:59:59';

-- Consulta 2: Salones con capacidad superior a 50 personas que están Disponibles
SELECT 
    salon_id, 
    nombre, 
    capacidad, 
    precio_hora, 
    estado 
FROM salones 
WHERE capacidad > 50 
AND estado = 'Disponible';

-- Consulta 3: Clientes corporativos con más de 3 reservas (Usando HAVING / GROUP BY)
SELECT 
    c.cliente_id,
    c.nombre_completo,
    c.identificacion,
    COUNT(r.reserva_id) AS total_reservas
FROM clientes c
INNER JOIN reservas r ON c.cliente_id = r.cliente_id
WHERE c.tipo_cliente = 'Corporativo'
GROUP BY c.cliente_id, c.nombre_completo, c.identificacion
HAVING COUNT(r.reserva_id) > 3;

-- Consulta 4: Verificar disponibilidad de un salón para un horario propuesto
-- Usa la función verificar_disponibilidad(salon_id, fecha_inicio, fecha_fin)
-- Caso A: horario que SÍ choca con una reserva confirmada del salón 1 -> retorna 0 (Ocupado)
SELECT verificar_disponibilidad(1, '2026-08-20 12:00:00', '2026-08-20 15:00:00') AS disponible_caso_ocupado;

-- Caso B: horario libre para el salón 1 -> retorna 1 (Disponible)
SELECT verificar_disponibilidad(1, '2026-10-01 09:00:00', '2026-10-01 12:00:00') AS disponible_caso_libre;