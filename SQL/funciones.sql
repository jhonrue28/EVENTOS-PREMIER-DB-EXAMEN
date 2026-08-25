-- ============================================================================
-- MÓDULO: Funciones Almacenadas (UDF)
-- OBJETIVO: Encapsular lógica de negocio para reutilización en consultas.
-- ============================================================================

USE eventos_premier;

DELIMITER //

-- ----------------------------------------------------------------------------
-- Función: calcular_total_reserva
-- Calcula el costo base por horas y aplica el IVA del 19%.
-- ----------------------------------------------------------------------------
CREATE FUNCTION calcular_total_reserva(
    p_precio_hora DECIMAL(10, 2),
    p_horas INT
) 
RETURNS DECIMAL(12, 2)
DETERMINISTIC
BEGIN
    DECLARE v_subtotal DECIMAL(12, 2);
    DECLARE v_total DECIMAL(12, 2);
    
    SET v_subtotal = p_precio_hora * p_horas;
    -- Aplicamos el 19% de IVA (Factor 1.19)
    SET v_total = v_subtotal * 1.19;
    
    RETURN v_total;
END;

-- ----------------------------------------------------------------------------
-- Función: verificar_disponibilidad
-- Comprueba si existe solapamiento de horario para un salón específico.
-- Retorna: 1 (Disponible) | 0 (Ocupado / Solapado)
-- ----------------------------------------------------------------------------
CREATE FUNCTION verificar_disponibilidad(
    p_salon_id INT,
    p_fecha_inicio DATETIME,
    p_fecha_fin DATETIME
) 
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_coincidencias INT;
    
    SELECT COUNT(*) 
    INTO v_coincidencias
    FROM reservas
    WHERE salon_id = p_salon_id
    AND estado_reserva = 'Confirmada'
    AND (
        (p_fecha_inicio >= fecha_inicio AND p_fecha_inicio < fecha_fin) OR
        (p_fecha_fin > fecha_inicio AND p_fecha_fin <= fecha_fin) OR
        (p_fecha_inicio <= fecha_inicio AND p_fecha_fin >= fecha_fin)
    );
    IF v_coincidencias > 0 THEN
        RETURN 0; -- Ocupado
    ELSE
        RETURN 1; -- Disponible
    END IF;
END;