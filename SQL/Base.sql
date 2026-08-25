-- ============================================================================
-- PROYECTO: Sistema de Reservas - Eventos Premier S.A.S.
-- MÓDULO: Creación de Base de Datos y Tablas (DDL)
-- OBJETIVO: Definir la estructura relacional con integridad referencial.
-- ============================================================================

DROP DATABASE IF EXISTS eventos_premier;
CREATE DATABASE eventos_premier CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE eventos_premier;

-- ----------------------------------------------------------------------------
-- Tabla: salones
-- Guarda los espacios disponibles para alquiler.
-- ----------------------------------------------------------------------------
CREATE TABLE salones (
    salon_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    capacidad INT NOT NULL CHECK (capacidad > 0),
    precio_hora DECIMAL(10, 2) NOT NULL CHECK (precio_hora > 0),
    -- Incluimos 'Ocupado' para permitir el control por triggers
    estado ENUM('Disponible', 'En mantenimiento', 'Ocupado') DEFAULT 'Disponible',
    encargado VARCHAR(100) NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Tabla: clientes
-- Registra los datos de contacto y categoría de los clientes.
-- ----------------------------------------------------------------------------
CREATE TABLE clientes (
    cliente_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre_completo VARCHAR(150) NOT NULL,
    identificacion VARCHAR(20) NOT NULL UNIQUE,
    telefono VARCHAR(20) NOT NULL,
    correo VARCHAR(100) NOT NULL UNIQUE,
    tipo_cliente ENUM('Individual', 'Corporativo') NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Tabla: reservas
-- Controla la agenda de alquileres asociando cliente y salón.
-- ----------------------------------------------------------------------------
CREATE TABLE reservas (
    reserva_id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    salon_id INT NOT NULL,
    fecha_inicio DATETIME NOT NULL,
    fecha_fin DATETIME NOT NULL,
    total_horas INT NOT NULL CHECK (total_horas > 0),
    valor_total DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    estado_reserva ENUM('Confirmada', 'Cancelada', 'Finalizada') DEFAULT 'Confirmada',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reservas_clientes FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_reservas_salones FOREIGN KEY (salon_id) REFERENCES salones(salon_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_fechas CHECK (fecha_fin > fecha_inicio)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Tabla: pagos
-- Historial de transacciones financieras ligadas a una reserva.
-- ----------------------------------------------------------------------------
CREATE TABLE pagos (
    pago_id INT AUTO_INCREMENT PRIMARY KEY,
    reserva_id INT NOT NULL,
    fecha_pago DATETIME DEFAULT CURRENT_TIMESTAMP,
    monto_pagado DECIMAL(12, 2) NOT NULL CHECK (monto_pagado > 0),
    metodo_pago ENUM('Efectivo', 'Tarjeta', 'Transferencia') NOT NULL,
    CONSTRAINT fk_pagos_reservas FOREIGN KEY (reserva_id) REFERENCES reservas(reserva_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Tabla: auditoria_precios
-- Guarda la trazabilidad de cambios en las tarifas por hora de los salones.
-- ----------------------------------------------------------------------------
CREATE TABLE auditoria_precios (
    auditoria_id INT AUTO_INCREMENT PRIMARY KEY,
    salon_id INT NOT NULL,
    precio_anterior DECIMAL(10, 2) NOT NULL,
    precio_nuevo DECIMAL(10, 2) NOT NULL,
    usuario VARCHAR(100) NOT NULL,
    fecha_cambio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_auditoria_salones FOREIGN KEY (salon_id) REFERENCES salones(salon_id) ON DELETE CASCADE
) ENGINE=InnoDB;