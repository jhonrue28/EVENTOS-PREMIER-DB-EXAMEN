
USE eventos_premier;



DROP FUNCTION IF EXISTS calcular_valor_pendiente;


CREATE FUNCTION calcular_valor_pendiente(
    total_reserva DECIMAL(12, 2),
    abono DECIMAL(12, 2)
)
RETURNS DECIMAL(12, 2)
DETERMINISTIC
BEGIN
    DECLARE v_pendiente DECIMAL(12, 2);


    SET v_pendiente = total_reserva - IFNULL(abono, 0);

    RETURN v_pendiente;
END;



SELECT
    c.nombre_completo                                          AS nombre_cliente,
    r.fecha_inicio                                              AS fecha_reserva,
    r.valor_total                                               AS total,
    IFNULL(p.abono, 0)                                          AS abono,
    calcular_valor_pendiente(r.valor_total, IFNULL(p.abono, 0)) AS valor_pendiente
FROM reservas r
INNER JOIN clientes c
    ON r.cliente_id = c.cliente_id
LEFT JOIN (
    SELECT reserva_id, SUM(monto_pagado) AS abono
    FROM pagos
    GROUP BY reserva_id
) p ON p.reserva_id = r.reserva_id
WHERE calcular_valor_pendiente(r.valor_total, IFNULL(p.abono, 0)) > 0
ORDER BY r.fecha_inicio;



CREATE OR REPLACE VIEW vista_facturacion_reservas AS
SELECT
    c.nombre_completo                                           AS nombre_cliente,
    r.fecha_inicio                                               AS fecha_reserva,
    r.valor_total                                                AS total_reserva,
    IFNULL(p.abono, 0)                                           AS abono,
    calcular_valor_pendiente(r.valor_total, IFNULL(p.abono, 0))  AS valor_pendiente
FROM reservas r
INNER JOIN clientes c
    ON r.cliente_id = c.cliente_id
LEFT JOIN (
    SELECT reserva_id, SUM(monto_pagado) AS abono
    FROM pagos
    GROUP BY reserva_id
) p ON p.reserva_id = r.reserva_id;



-- Tabla de auditoría de abonos
DROP TABLE IF EXISTS auditoria_abonos;

CREATE TABLE auditoria_abonos (
    id_auditoria    INT AUTO_INCREMENT PRIMARY KEY,
    id_pago         INT NOT NULL,
    fecha_movimiento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valor_anterior  DECIMAL(12, 2) NULL,
    valor_nuevo     DECIMAL(12, 2) NOT NULL,
    usuario         VARCHAR(100) NOT NULL,
    CONSTRAINT fk_auditoria_abonos_pagos FOREIGN KEY (id_pago) REFERENCES pagos(pago_id) ON DELETE CASCADE
) ENGINE=InnoDB;

DROP TRIGGER IF EXISTS auditar_abono_trigger;
DROP TRIGGER IF EXISTS auditar_abono_update_trigger;



CREATE TRIGGER auditar_abono_trigger
AFTER INSERT ON pagos
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_abonos (
        id_pago,
        valor_anterior,
        valor_nuevo,
        usuario
    ) VALUES (
        NEW.pago_id,
        NULL,
        NEW.monto_pagado,
        CURRENT_USER()
    );
END;


CREATE TRIGGER auditar_abono_update_trigger
AFTER UPDATE ON pagos
FOR EACH ROW
BEGIN
    IF OLD.monto_pagado <> NEW.monto_pagado THEN
        INSERT INTO auditoria_abonos (
            id_pago,
            valor_anterior,
            valor_nuevo,
            usuario
        ) VALUES (
            NEW.pago_id,
            OLD.monto_pagado,
            NEW.monto_pagado,
            CURRENT_USER()
        );
    END IF;
END;



SELECT
    c.nombre_completo                    AS nombre_cliente,
    COUNT(*)                             AS reservas_completadas
FROM reservas r
INNER JOIN clientes c
    ON r.cliente_id = c.cliente_id
LEFT JOIN (
    SELECT reserva_id, SUM(monto_pagado) AS abono
    FROM pagos
    GROUP BY reserva_id
) p ON p.reserva_id = r.reserva_id
WHERE calcular_valor_pendiente(r.valor_total, IFNULL(p.abono, 0)) <= 0
GROUP BY c.cliente_id, c.nombre_completo
ORDER BY reservas_completadas DESC
LIMIT 3;