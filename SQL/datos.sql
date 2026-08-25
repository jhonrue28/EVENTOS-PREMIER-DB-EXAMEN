-- =============================================================================
-- PROYECTO: Eventos Premier S.A.S.
-- MÓDULO: DML (Data Manipulation Language) / Datos de Prueba (Seed)
-- DESCRIPCIÓN: Inserción de datos iniciales para probar salones, clientes,
--              reservas, pagos, funciones, triggers y auditorías.
-- =============================================================================

USE eventos_premier;

-- Desactivar temporalmente restricciones para recarga limpia si se ejecuta de nuevo
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE pagos;
TRUNCATE TABLE reservas;
TRUNCATE TABLE auditoria_precios;
TRUNCATE TABLE clientes;
TRUNCATE TABLE salones;
SET FOREIGN_KEY_CHECKS = 1;

-- -----------------------------------------------------------------------------
-- 1. POBLADO DE SALONES
-- -----------------------------------------------------------------------------
INSERT INTO salones (nombre, capacidad, precio_hora, estado, encargado) VALUES
('Gran Salón Real', 200, 150000.00, 'Disponible', 'Carlos Mendoza'),
('Salón Ejecutivo Alfa', 30, 60000.00, 'Disponible', 'Andrea Gómez'),
('Salón VIP Diamante', 80, 110000.00, 'Disponible', 'Carlos Mendoza'),
('Auditorio Empresarial', 120, 130000.00, 'En mantenimiento', 'Laura Restrepo'),
('Salón de Fiestas Aurora', 150, 95000.00, 'Disponible', 'Felipe Ortiz');

-- -----------------------------------------------------------------------------
-- 2. POBLADO DE CLIENTES
-- Incluye clientes naturales y corporativos (con uno de ellos acumulando >3 reservas)
-- -----------------------------------------------------------------------------
INSERT INTO clientes (nombre_completo, identificacion, telefono, correo, tipo_cliente) VALUES
('Tech Solutions S.A.S.', 'NIT 900123456-1', '3158889900', 'eventos@techsolutions.com', 'Corporativo'),
('Constructora Santander S.A.', 'NIT 890987654-3', '3104445566', 'contacto@constructorasnt.com', 'Corporativo'),
('María Fernanda Silva', 'CC 1098765432', '3001234567', 'maria.silva@email.com', 'Individual'),
('Inversiones Globales SAS', 'NIT 901555444-2', '3187772211', 'gerencia@inglobales.com', 'Corporativo'),
('Julián Ricardo Pérez', 'CC 91234567', '3129998877', 'julian.perez@email.com', 'Individual');

-- -----------------------------------------------------------------------------
-- 3. POBLADO DE RESERVAS
-- Hacemos uso de la función `calcular_total_reserva` para registrar los valores totales
-- -----------------------------------------------------------------------------

-- Reservas de 'Tech Solutions S.A.S.' (Cliente ID 1) -> Más de 3 reservas para probar subconsulta
INSERT INTO reservas (cliente_id, salon_id, fecha_inicio, fecha_fin, total_horas, valor_total, estado_reserva) VALUES
(1, 1, '2026-08-05 08:00:00', '2026-08-05 12:00:00', 4.00, calcular_total_reserva(150000.00, 4.00), 'Finalizada'),
(1, 2, '2026-08-10 14:00:00', '2026-08-10 18:00:00', 4.00, calcular_total_reserva(60000.00, 4.00), 'Finalizada'),
(1, 3, '2026-08-15 09:00:00', '2026-08-15 13:00:00', 4.00, calcular_total_reserva(110000.00, 4.00), 'Finalizada'),
(1, 1, '2026-08-20 10:00:00', '2026-08-20 16:00:00', 6.00, calcular_total_reserva(150000.00, 6.00), 'Confirmada');

-- Reservas adicionales para otros clientes en agosto de 2026
INSERT INTO reservas (cliente_id, salon_id, fecha_inicio, fecha_fin, total_horas, valor_total, estado_reserva) VALUES
(2, 3, '2026-08-12 15:00:00', '2026-08-12 20:00:00', 5.00, calcular_total_reserva(110000.00, 5.00), 'Confirmada'),
(3, 5, '2026-08-25 18:00:00', '2026-08-26 01:00:00', 7.00, calcular_total_reserva(95000.00, 7.00), 'Confirmada'),
(4, 2, '2026-09-02 08:00:00', '2026-09-02 12:00:00', 4.00, calcular_total_reserva(60000.00, 4.00), 'Confirmada');

-- -----------------------------------------------------------------------------
-- 4. POBLADO DE PAGOS
-- -----------------------------------------------------------------------------
INSERT INTO pagos (reserva_id, fecha_pago, monto_pagado, metodo_pago) VALUES
(1, '2026-08-01 10:30:00', 714000.00, 'Transferencia'),
(2, '2026-08-08 11:15:00', 285600.00, 'Tarjeta'),
(3, '2026-08-13 16:00:00', 523600.00, 'Transferencia'),
(4, '2026-08-18 09:00:00', 1071000.00, 'Transferencia'),
(5, '2026-08-11 14:20:00', 654500.00, 'Tarjeta'),
(6, '2026-08-22 10:00:00', 793150.00, 'Efectivo');

-- =============================================================================
-- PRUEBAS EXPLICITAS DE COMPONENTES Y TRIGGERS
-- =============================================================================

-- A. PRUEBA DEL TRIGGER DE AUDITORÍA DE PRECIOS
-- Modificamos el precio por hora del Salón ID 1 y ID 2
UPDATE salones SET precio_hora = 165000.00 WHERE salon_id = 1;
UPDATE salones SET precio_hora = 65000.00 WHERE salon_id = 2;

-- B. PRUEBA DEL TRIGGER DE ESTADO (actualizar_estado_salon_trigger)
-- Al insertar una nueva reserva activa para el Salón 5, su estado cambia automáticamente a 'Ocupado'
INSERT INTO reservas (cliente_id, salon_id, fecha_inicio, fecha_fin, total_horas, valor_total, estado_reserva)
VALUES (5, 5, '2026-08-28 14:00:00', '2026-08-28 18:00:00', 4.00, calcular_total_reserva(95000.00, 4.00), 'Confirmada');

-- C. PRUEBA DEL TRIGGER DE LIBERACIÓN (liberar_salon_trigger)
-- Eliminamos una reserva de prueba sobre el Salón 5 para verificar que su estado pasa de nuevo a 'Disponible'
DELETE FROM reservas WHERE cliente_id = 5 AND salon_id = 5;