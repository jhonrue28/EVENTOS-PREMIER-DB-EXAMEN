
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



