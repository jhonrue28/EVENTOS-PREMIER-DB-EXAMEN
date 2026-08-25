-- ============================================================================
-- MÓDULO: Triggers
-- OBJETIVO: Automatizar estados y asegurar auditoría de datos.
-- ============================================================================

USE eventos_premier;


-- ----------------------------------------------------------------------------
-- Trigger: actualizar_estado_salon_trigger
-- Cambia automáticamente el estado del salón a 'Ocupado' tras insertar una reserva.
-- ----------------------------------------------------------------------------
CREATE TRIGGER actualizar_estado_salon_trigger
AFTER INSERT ON reservas
FOR EACH ROW
BEGIN
    UPDATE salones 
    SET estado = 'Ocupado'
    WHERE salon_id = NEW.salon_id;
END;

-- ----------------------------------------------------------------------------
-- Trigger: liberar_salon_trigger
-- Restablece el estado del salón a 'Disponible' al eliminar una reserva.
-- ----------------------------------------------------------------------------
CREATE TRIGGER liberar_salon_trigger
AFTER DELETE ON reservas
FOR EACH ROW
BEGIN
    UPDATE salones 
    SET estado = 'Disponible'
    WHERE salon_id = OLD.salon_id;
END;


-- Trigger: auditoria_precios_trigger
-- Registra en historial cada modificación al precio por hora de un salón.
CREATE TRIGGER IF NOT EXISTS auditoria_precios_trigger
AFTER UPDATE ON salones
FOR EACH ROW
BEGIN
    IF OLD.precio_hora <> NEW.precio_hora THEN
        INSERT INTO auditoria_precios (
            salon_id,
            precio_anterior,
            precio_nuevo,
            usuario
        ) VALUES (
            NEW.salon_id,
            OLD.precio_hora,    -- Valor que tenía el salón antes del UPDATE
            NEW.precio_hora,    -- Valor nuevo que se acaba de asignar
            CURRENT_USER()
        );
    END IF;
END;