# 🏢 Sistema de Gestión de Reservas - Eventos Premier S.A.S.

## 📌 Descripción del proyecto

Eventos Premier S.A.S. es una empresa dedicada al alquiler de salones para reuniones, fiestas y conferencias. Este repositorio contiene la base de datos relacional que digitaliza el proceso de reservas, desarrollada sobre **MySQL 8.0**.

El sistema permite al personal administrativo:

- Gestionar salones (capacidad, precio por hora, estado, encargado).
- Gestionar clientes individuales y corporativos.
- Registrar reservas calculando automáticamente el valor total (con IVA del 19%).
- Registrar pagos asociados a cada reserva.
- Consultar disponibilidad de salones en tiempo real.
- Auditar cambios en las tarifas de los salones.
- Generar reportes de uso mediante vistas y consultas de negocio.

---

## 📁 Estructura del repositorio

```text
.
├── Base.sql        # Definición de tablas e integridad referencial (DDL)
├── funciones.sql    # Funciones almacenadas (cálculo de total, disponibilidad)
├── triggers.sql      # Triggers de cambio de estado y auditoría
├── vistas.sql # Vista de resumen + consultas de negocio requeridas
├── datos.sql          # Datos de prueba (seed) y pruebas explícitas de triggers
└── README.md                # Documentación y guía de uso
```

### Modelo relacional

```
salones (1) ────< reservas >──── (1) clientes
                      │
                      └──< pagos

salones (1) ────< auditoria_precios
```

- Una **reserva** pertenece a un único **cliente** y a un único **salón**.
- Un **salón** o **cliente** puede tener muchas **reservas** (relación 1:N).
- Una **reserva** puede tener uno o varios **pagos** asociados (relación 1:N).
- Cada cambio de precio en un **salón** genera un registro en **auditoria_precios**.

---

# Modelo entidad-relación
![Modelo entidad relación proyecto](<img/modeloentidadrelacion.png>)

- Una reserva pertenece a un único cliente y a un único salón → relación realiza (clientes 1 : N reservas) y dispone (salones 1 : N reservas).
- Una reserva puede generar uno o varios pagos → relación genera (1 : N).
- Cada cambio de precio en un salón queda registrado en auditoria_precios → relación audita (1 : N).

## ⚙️ Instrucciones de ejecución

Clonar el repositorio y ejecutar los scripts **en este orden** (el orden importa por las llaves foráneas y porque `datos.sql` usa las funciones creadas en `funciones.sql`):

```bash
git clone https://github.com/jhonrue28/EVENTOS-PREMIERE-DB
cd EVENTOS-PREMIERE-DB

mysql -u tu_usuario -p < Base.sql
mysql -u tu_usuario -p < funciones.sql
mysql -u tu_usuario -p < triggers.sql
mysql -u tu_usuario -p < datos.sql
mysql -u tu_usuario -p < vistas.sql
```

> 💡 `datos.sql` incluye al final pruebas explícitas de los tres triggers (auditoría de precios, ocupación de salón y liberación de salón), por lo que se recomienda revisarlas tras la carga.

---

## 🧮 Funciones

### `calcular_total_reserva(precio_hora, horas)`
Calcula el valor total de una reserva aplicando IVA del 19%.

```sql
SELECT calcular_total_reserva(150000.00, 4) AS total_con_iva;
-- Resultado: 714000.00  → (150000 * 4) * 1.19
```

### `verificar_disponibilidad(salon_id, fecha_inicio, fecha_fin)`
Retorna `1` si el salón está disponible en ese rango de fechas, o `0` si ya tiene una reserva confirmada que se solapa.

```sql
-- Horario que choca con una reserva existente del salón 1
SELECT verificar_disponibilidad(1, '2026-08-20 12:00:00', '2026-08-20 15:00:00');
-- Resultado: 0 (Ocupado)

-- Horario libre
SELECT verificar_disponibilidad(1, '2026-10-01 09:00:00', '2026-10-01 12:00:00');
-- Resultado: 1 (Disponible)
```

---

## ⚡ Triggers

| Trigger | Evento | Acción |
|---|---|---|
| `actualizar_estado_salon_trigger` | `AFTER INSERT` en `reservas` | Cambia el `estado` del salón a `'Ocupado'` |
| `liberar_salon_trigger` | `AFTER DELETE` en `reservas` | Cambia el `estado` del salón a `'Disponible'` |
| `auditoria_precios_trigger` | `AFTER UPDATE` en `salones` | Si `precio_hora` cambió, inserta un registro en `auditoria_precios` con usuario, fecha, valor anterior y nuevo |

Ejemplo — auditoría de precio:

```sql
UPDATE salones SET precio_hora = 165000.00 WHERE salon_id = 1;

SELECT * FROM auditoria_precios WHERE salon_id = 1;
-- Muestra: precio_anterior = 150000.00, precio_nuevo = 165000.00, usuario, fecha_cambio
```

---

## 🔍 Vista y consultas de negocio

### Vista `vista_resumen_reservas`
Consolida cliente, salón, fechas, valor total y estado, sin exponer IDs técnicos.

```sql
SELECT * FROM vista_resumen_reservas;
```

### Consultas incluidas en `vistas.sql`

1. **Reservas en un rango de fechas** (`BETWEEN`) — reservas de septiembre 2026.
2. **Salones disponibles con capacidad > 50** personas.
3. **Clientes corporativos con más de 3 reservas** (`GROUP BY` + `HAVING COUNT`).
4. **Disponibilidad de un salón** para un horario propuesto, usando `verificar_disponibilidad()`.

---

## 💳 Examen - Módulo de pagos

El archivo `SQL/EXAMEN_Eventos Premier S.A.S..sql` contiene los entregables del
examen del módulo de pagos:

- Función `calcular_valor_pendiente(total_reserva, abono)`.
- Consulta de reservas con pagos pendientes.
- Vista `vista_facturacion_reservas`.
- Tabla `auditoria_abonos` y trigger `auditar_abono_trigger` (más su
  complemento `auditar_abono_update_trigger` para el evento `UPDATE`, ya que
  MySQL requiere un trigger por cada evento).
- Consulta de los 3 clientes que más reservas han pagado por completo.

Este script debe ejecutarse **después** de `Base.sql`, `funciones.sql`,
`triggers.sql` y `datos.sql`, ya que depende de las tablas `clientes`,
`reservas` y `pagos` ya creadas y pobladas:

```bash
mysql -u tu_usuario -p eventos_premier < "SQL/EXAMEN_Eventos Premier S.A.S..sql"
```

---

## 👤 Créditos y autor

- **Autor:** _[Tu nombre aquí]_
- **Curso / Asignatura:** _[Nombre del curso]_
- **Profesor:** _[Nombre del profesor]_
- **Motor de base de datos:** MySQL 8.0
