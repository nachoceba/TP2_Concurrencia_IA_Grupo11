-- =============================================================================
-- TP2 Concurrencia IA Grupo 11 - Optimizacion de consultas (indices.sql)
-- Motor: PostgreSQL 18.6 | Base: clon de TP2_Concurrencia_IA_Grupo11
-- Origen: capturas EXPLAIN ANALYZE SELECT * FROM usuario / producto / pedido
--   * usuario  (20.000 filas): Seq Scan, Execution ~1.075 ms
--   * producto (50.000 filas): Seq Scan, Execution ~2.720 ms
--   * pedido  (200.000 filas): Seq Scan, Execution ~10.707 ms
-- Diagnostico: SELECT * sin WHERE/JOIN/ORDER BY/LIMIT obliga a Seq Scan.
--   Ningun indice B-tree acelera el barrido total. La mejora real es:
--   1) Reescribir a consultas selectivas (columnas + WHERE + LIMIT), y
--   2) Indexar los predicados de ese workload real (ver Seccion B).
-- Indices ya existentes en schema.sql (NO duplicar):
--   idx_producto_categoria_id, idx_pedido_usuario_id, idx_pedido_fecha,
--   idx_pedido_estado, idx_detalle_pedido_pedido_id,
--   idx_detalle_pedido_producto_id, UNIQUE(usuario.mail)
-- =============================================================================
-- PROTOCOLO DE SEGURIDAD (protocolo_seguridad.md) - OBLIGATORIO:
--   Paso 1 (Clon, nunca sobre la principal):
--     dropdb -U postgres TP2_Concurrencia_IA_Grupo11_clon --if-exists;
--     createdb -U postgres -T TP2_Concurrencia_IA_Grupo11 TP2_Concurrencia_IA_Grupo11_clon;
--     psql -U postgres -d TP2_Concurrencia_IA_Grupo11_clon -f indices.sql
--   Paso 2 (Transaccion: probar con ROLLBACK antes del COMMIT definitivo):
--     BEGIN; \i indices.sql  -- inspeccionar mensajes, luego ROLLBACK o COMMIT
--     NOTA: este archivo NO usa CONCURRENTLY a proposito para ser
--     transaccional. La variante CONCURRENTLY (no transaccional) se indica
--     en cada caso como alternativa para produccion sin bloqueo de escritura.
--   Paso 3 (Respaldo antes de aplicar):
--     pg_dump -U postgres -Fc TP2_Concurrencia_IA_Grupo11_clon > backup_pre_indices.dump
--   Post-aplicacion: VACUUM ANALYZE; y re-medir con
--     EXPLAIN (ANALYZE, BUFFERS, TIMING) <consulta>;
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- A. EXTENSION PARA BUSQUEDA DE TEXTO (solo si se usa ILIKE '%...%')
--    Sin trigram, LIKE con comodin inicial no usa B-tree.
-- -----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- -----------------------------------------------------------------------------
-- B. INDICES PROPUESTOS (idempotentes)
-- -----------------------------------------------------------------------------

-- B1. Soft-delete parciales: todo el workload de negocio filtra eliminado=FALSE.
--     Parcial = mas chico y mas rapido que indexar toda la tabla.
CREATE INDEX IF NOT EXISTS idx_producto_activo
    ON producto (id_producto) WHERE eliminado = FALSE;
-- Alternativa produccion: CREATE INDEX CONCURRENTLY ...

CREATE INDEX IF NOT EXISTS idx_pedido_activo
    ON pedido (id_pedido) WHERE eliminado = FALSE;

CREATE INDEX IF NOT EXISTS idx_usuario_activo
    ON usuario (id_usuario) WHERE eliminado = FALSE;

CREATE INDEX IF NOT EXISTS idx_categoria_activa
    ON categoria (id_categoria) WHERE eliminado = FALSE;

-- B2. Catalogo: filtro tipico categoria + disponibilidad + orden por precio.
--     Cubre reescritura Q1. Complementa (no duplica) idx_producto_categoria_id.
CREATE INDEX IF NOT EXISTS idx_producto_categoria_disponible
    ON producto (categoria_id, disponible) WHERE eliminado = FALSE;

CREATE INDEX IF NOT EXISTS idx_producto_categoria_precio
    ON producto (categoria_id, precio) WHERE eliminado = FALSE AND disponible = TRUE;

-- B3. Pedidos por usuario + fecha (Q2). Compuesto (usuario_id, fecha DESC).
--     Supera al simple idx_pedido_usuario_id cuando hay ORDER BY fecha LIMIT.
CREATE INDEX IF NOT EXISTS idx_pedido_usuario_fecha
    ON pedido (usuario_id, fecha DESC) WHERE eliminado = FALSE;

-- B4. Pedidos por estado + fecha (Q3). Compuesto (estado, fecha DESC).
--     Supera a los simples idx_pedido_estado / idx_pedido_fecha por separado.
CREATE INDEX IF NOT EXISTS idx_pedido_estado_fecha
    ON pedido (estado, fecha DESC) WHERE eliminado = FALSE;

-- B5. Detalle de un pedido (Q4): covering para Index-Only Scan.
--     Evita ir al heap por cantidad/subtotal/producto_id.
CREATE INDEX IF NOT EXISTS idx_detalle_pedido_covering
    ON detalle_pedido (pedido_id) INCLUDE (producto_id, cantidad, subtotal);

-- B6. Top-productos / joins inversos: buscar pedidos que contienen un producto.
CREATE INDEX IF NOT EXISTS idx_detalle_producto_pedido
    ON detalle_pedido (producto_id, pedido_id);

-- B7. Login por mail (Q5): ya existe UNIQUE(usuario.mail) -> B-tree implicito.
--     NO se crea nada. Solo reescribir SELECT * -> columnas (ver Q5 abajo).

-- B8. Busqueda por nombre (Q6, opcional, solo si la app usa ILIKE).
--     GIN trigram: unico que acelera '%texto%'.
CREATE INDEX IF NOT EXISTS idx_producto_nombre_trgm
    ON producto USING GIN (nombre gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_usuario_apellido_trgm
    ON usuario USING GIN (apellido gin_trgm_ops);

COMMIT;

-- Post-aplicacion (fuera de transaccion): actualizar estadisticas del planner.
-- Ejecutar manualmente: VACUUM ANALYZE producto; VACUUM ANALYZE pedido;
--   VACUUM ANALYZE usuario; VACUUM ANALYZE detalle_pedido;

-- =============================================================================
-- C. REESCRITURAS PROPUESTAS (antes -> despues)
--    Medir cada una con: EXPLAIN (ANALYZE, BUFFERS, TIMING) <consulta>;
--    Objetivo: pasar de Seq Scan + Heap Fetches altos a
--    Index Scan / Bitmap Heap Scan / Index Only Scan con Buffers bajos.
-- =============================================================================

-- Q1. Catalogo por categoria (antes: SELECT * FROM producto)
-- ANTES (barre 50k filas): SELECT * FROM producto;
-- DESPUES (usa idx_producto_categoria_disponible / idx_producto_categoria_precio):
-- EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT id_producto, nombre, precio, stock
FROM producto
WHERE categoria_id = 1
  AND disponible = TRUE
  AND eliminado = FALSE
ORDER BY precio
LIMIT 50;

-- Q2. Pedidos de un usuario, paginado keyset (antes: SELECT * FROM pedido)
-- ANTES (barre 200k filas): SELECT * FROM pedido;
-- DESPUES (usa idx_pedido_usuario_fecha). Primera pagina:
-- EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT id_pedido, fecha, estado, total
FROM pedido
WHERE usuario_id = 1
  AND eliminado = FALSE
ORDER BY fecha DESC
LIMIT 20;
-- Pagina siguiente (evita OFFSET grande):
-- SELECT id_pedido, fecha, estado, total FROM pedido
-- WHERE usuario_id = 1 AND eliminado = FALSE AND id_pedido < $cursor
-- ORDER BY fecha DESC LIMIT 20;

-- Q3. Pedidos por estado y rango de fecha (usa idx_pedido_estado_fecha)
-- EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT id_pedido, fecha, total, usuario_id
FROM pedido
WHERE estado = 'PENDIENTE'
  AND fecha BETWEEN CURRENT_DATE - 30 AND CURRENT_DATE
  AND eliminado = FALSE
ORDER BY fecha DESC
LIMIT 100;

-- Q4. Detalle de un pedido con nombre de producto
-- (usa idx_detalle_pedido_covering + PK de producto)
-- EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT d.cantidad, d.precio_unitario, d.subtotal, p.nombre
FROM detalle_pedido d
JOIN producto p ON p.id_producto = d.producto_id
WHERE d.pedido_id = 1;

-- Q5. Login / lookup por mail (usa el UNIQUE existente, sin indice nuevo)
-- ANTES: SELECT * FROM usuario;
-- DESPUES (Index Scan en el UNIQUE, solo columnas necesarias):
-- EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT id_usuario, nombre, rol
FROM usuario
WHERE mail = 'cliente_1@foodstore.com'
  AND eliminado = FALSE;

-- Q6. Busqueda por nombre (usa idx_producto_nombre_trgm). Solo con ILIKE '%x%'.
-- Sin trigram esta consulta siempre es Seq Scan.
-- EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT id_producto, nombre, precio
FROM producto
WHERE nombre ILIKE '%Pizza%'
  AND eliminado = FALSE
LIMIT 20;

-- Q7. Agregado: ventas del ultimo mes (usa idx_pedido_estado_fecha + covering detalle)
-- EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT date_trunc('month', p.fecha) AS mes, SUM(d.subtotal) AS ventas
FROM pedido p
JOIN detalle_pedido d ON d.pedido_id = p.id_pedido
WHERE p.estado = 'TERMINADO'
  AND p.fecha >= CURRENT_DATE - 30
  AND p.eliminado = FALSE
GROUP BY 1;

-- =============================================================================
-- D. VERIFICACION ESPERADA (que informar en el TP)
--   * Q1-Q5: Seq Scan -> Index Scan o Bitmap Heap Scan; Execution Time baja
--     y Buffers (shared hit) cae porque ya no se lee toda la tabla.
--   * SELECT * literales de las capturas: SEGUIRAN dando Seq Scan (es lo
--     correcto). Incluirlos como "caso testigo": demuestran que el indice
--     no se usa sin WHERE, lo cual valida el diagnostico.
--   * Si algun indice nuevo no cambia ningun plan (EXPLAIN no lo usa),
--     ELIMINARLO: cada indice penaliza INSERT/UPDATE en detalle_pedido y
--     pedido, tablas criticas para la Parte 2 (concurrencia/bloqueos).
--   * Rollback de emergencia: DROP INDEX IF EXISTS <nombre>; o restaurar
--     backup_pre_indices.dump del Paso 3.
-- =============================================================================
