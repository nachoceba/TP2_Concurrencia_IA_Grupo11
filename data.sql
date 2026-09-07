-- =============================================================================
-- Food Store - Script de Poblacion Masiva Sintetica (data.sql)
-- Motor: PostgreSQL 18.6 | Base vacia post schema.sql
-- Volumen: 12 categorias | 50.000 productos | 20.000 usuarios | 200.000 pedidos | ~500-600k detalles
-- Autor: DBA Senior - Generado para TP2 Concurrencia IA Grupo 11
-- Requerimientos tecnicos:
--   * Set-Based exclusivo: INSERT INTO ... SELECT generate_series(...) (PROHIBIDO LOOP/FOR/cursores)
--   * Transaccional: BEGIN; ... COMMIT; (protocolo_seguridad.md Paso 2)
--   * Secuencias sincronizadas con pg_get_serial_sequence + setval
--   * Respeta CK: ck_producto_disponible_stock y ck_detalle_subtotal
--   * Precios 1.500-35.000 | stock 0-500 | disponible 90% (FALSE si stock=0)
--   * mail UNIQUE cliente_<id>@foodstore.com | bcrypt simulado
--   * pedido.total y detalle.subtotal calculados (compat. con triggers objects.sql)
-- Uso segun protocolo_seguridad.md:
--   1) dropdb ... --if-exists && createdb -T TP2_Concurrencia_IA_Grupo11 clon
--   2) psql -d clon -f data.sql  (primero con ROLLBACK de prueba)
--   3) pg_dump -Fc clon > backup.dump
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- 0. Configuracion de sesion para carga masiva (revertida al COMMIT)
-- -----------------------------------------------------------------------------
SET LOCAL synchronous_commit TO OFF;
SET LOCAL statement_timeout TO 0;
SET LOCAL lock_timeout TO 0;

-- -----------------------------------------------------------------------------
-- 1. CATEGORIAS (12 gastronomicas reales)
-- -----------------------------------------------------------------------------
INSERT INTO categoria (nombre, descripcion, eliminado) VALUES
 ('Hamburguesas', 'Hamburguesas gourmet, clasicas y dobles', FALSE),
 ('Pizzas', 'Pizzas a la piedra y al molde', FALSE),
 ('Empanadas', 'Empanadas fritas y al horno', FALSE),
 ('Bebidas', 'Gaseosas, aguas, cervezas y jugos', FALSE),
 ('Postres', 'Helados, tortas y dulces', FALSE),
 ('Papas Fritas', 'Papas fritas y papas rusticas', FALSE),
 ('Combos', 'Combos familiares y promociones', FALSE),
 ('Milanesas', 'Milanesas de carne, pollo y vegetarianas', FALSE),
 ('Pastas', 'Pastas caseras y salsas', FALSE),
 ('Ensaladas', 'Ensaladas frescas y bowls', FALSE),
 ('Sándwiches', 'Sándwiches y lomitos', FALSE),
 ('Helados', 'Helados artesanales por kilo y vasito', FALSE);

-- -----------------------------------------------------------------------------
-- 2. PRODUCTOS (50.000 filas) - Set-Based, sin LOOP
--    - Nombres: combinacion bases + variantes + sufijo #id para realismo
--    - Precios: 1.500 - 35.000 coherente gastronomia
--    - stock 0-500, disponible 90% TRUE (FALSE obligatorio si stock=0 por CK)
--    - categoria_id distribuido uniformemente 1..12 (base vacia, ids 1-12)
-- -----------------------------------------------------------------------------
INSERT INTO producto (nombre, precio, descripcion, stock, imagen, disponible, categoria_id, eliminado)
SELECT
    b.bases[1 + floor(random()*array_length(b.bases,1))::int]
    || ' ' ||
    v.variantes[1 + floor(random()*array_length(v.variantes,1))::int]
    || ' #' || gs AS nombre,
    round((1500 + random()*33500)::numeric, 2) AS precio,
    'Producto Food Store - ' || b.bases[1 + floor(random()*array_length(b.bases,1))::int] AS descripcion,
    s.stock AS stock,
    'img/producto_' || gs || '.jpg' AS imagen,
    CASE WHEN s.stock = 0 THEN FALSE ELSE (random() < 0.90) END AS disponible,
    1 + (gs % 12) AS categoria_id,
    FALSE AS eliminado
FROM generate_series(1, 50000) AS gs
CROSS JOIN (SELECT ARRAY[
    'Hamburguesa','Pizza','Empanada','Milanesa','Lomito','Papas','Ensalada','Pasta',
    'Sándwich','Taco','Bebida','Postre','Combo','Wrap','Panchito','Arepa','Burrito',
    'Ensalada Caesar','Ravioles','Ñoquis','Asado','Choripán','Fajita','Hot Dog'
]::text[] AS bases) AS b
CROSS JOIN (SELECT ARRAY[
    'Clásica','Especial de la Casa','Doble con Queso','Picante','Vegetariana','Premium',
    'XL','con Cheddar','de la Abuela','BBQ','4 Quesos','Napolitana','Completa','Crispy',
    'a la Provenzal','con Bacon','Veggie','Tradicional','Gourmet','del Chef','Familiar',
    'Individual','con Papas','sin TACC','Light'
]::text[] AS variantes) AS v
CROSS JOIN LATERAL (SELECT floor(random()*501)::int AS stock) AS s;

-- -----------------------------------------------------------------------------
-- 3. USUARIOS (20.000 filas) - Set-Based
--    - mail UNIQUE: cliente_<id>@foodstore.com
--    - contrasena: hash bcrypt simulado $2b$12$...
--    - rol: 95% USUARIO, 5% ADMIN
-- -----------------------------------------------------------------------------
INSERT INTO usuario (nombre, apellido, mail, celular, contrasena, rol, eliminado)
SELECT
    n.nombres[1 + floor(random()*array_length(n.nombres,1))::int] AS nombre,
    a.apellidos[1 + floor(random()*array_length(a.apellidos,1))::int] AS apellido,
    'cliente_' || gs || '@foodstore.com' AS mail,
    '11' || lpad((30000000 + floor(random()*7000000)::int)::text, 8, '0') AS celular,
    '$2b$12$' || substr(md5(random()::text), 1, 53) AS contrasena,
    CASE WHEN random() < 0.05 THEN 'ADMIN'::rol_usuario ELSE 'USUARIO'::rol_usuario END AS rol,
    FALSE AS eliminado
FROM generate_series(1, 20000) AS gs
CROSS JOIN (SELECT ARRAY[
    'Juan','María','Pedro','Lucía','Santiago','Valentina','Matías','Sofía','Nicolás','Florencia',
    'Agustín','Camila','Martín','Julieta','Lautaro','Micaela','Facundo','Agostina','Tomás','Gonzalo',
    'Carla','Diego','Paula','Ramiro','Emmanuel','Franco','Ignacio','Ciro','Santiago','Luciano',
    'Milagros','Joaquín','Candela','Lucas','Victoria','Thiago','Morena','Benjamín','Martina','Felipe'
]::text[] AS nombres) AS n
CROSS JOIN (SELECT ARRAY[
    'González','Pérez','Rodríguez','García','López','Martínez','Fernández','Gómez','Díaz','Torres',
    'Ruiz','Sosa','Ramírez','Álvarez','Benítez','Acosta','Rojas','Molina','Suárez','Romero',
    'Herrera','Medina','Silva','Castro','Ortega','Gutiérrez','Vázquez','Quiroga','Miranda','Ceballos',
    'Cattáneo','Copia','Gagliardi','Flores','Sánchez','Morales','Ríos','Navarro','Domínguez','Aguirre'
]::text[] AS apellidos) AS a;

-- -----------------------------------------------------------------------------
-- 4. PEDIDOS (200.000 filas) - Set-Based
--    - fecha: CURRENT_DATE - random()*730 (ultimos 2 años)
--    - usuario_id: 1..20000 aleatorio (base vacia)
--    - estado / forma_pago: random desde ENUMs
--    - total: 0 (sera recalculado tras detalles; trigger o UPDATE lo corrige)
-- -----------------------------------------------------------------------------
INSERT INTO pedido (fecha, estado, total, forma_pago, usuario_id, eliminado)
SELECT
    (CURRENT_DATE - (floor(random()*730)::int)) AS fecha,
    (ARRAY['PENDIENTE','CONFIRMADO','TERMINADO','CANCELADO']::estado_pedido[])[1 + floor(random()*4)::int] AS estado,
    0::numeric(10,2) AS total,
    (ARRAY['EFECTIVO','TARJETA','TRANSFERENCIA']::forma_pago[])[1 + floor(random()*3)::int] AS forma_pago,
    1 + floor(random()*20000)::int AS usuario_id,
    FALSE AS eliminado
FROM generate_series(1, 200000) AS gs;

-- -----------------------------------------------------------------------------
-- 5. DETALLE_PEDIDO (1-4 items por pedido => ~500-600k filas) - Set-Based
--    - Sin LOOP: CROSS JOIN LATERAL generate_series(1, 1+floor(random()*4))
--    - cantidad 1-5, producto_id 1..50000 aleatorio
--    - precio_unitario = producto.precio (precio congelado real)
--    - subtotal = cantidad * precio_unitario (respeta ck_detalle_subtotal)
--    NOTA: Si existen triggers trg_subtotal / trg_total_ins (objects.sql) el
--    calculo es redundante pero inocuo y garantiza CK incluso si triggers no existen.
--    Para max performance descomentar DISABLE TRIGGER ALL antes y ENABLE despues.
-- -----------------------------------------------------------------------------
-- ALTER TABLE detalle_pedido DISABLE TRIGGER ALL; -- opcional: comentar/descomentar segun necesites

INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario, subtotal)
SELECT
    p.id_pedido AS pedido_id,
    prod.id_producto AS producto_id,
    det.cantidad AS cantidad,
    prod.precio AS precio_unitario,
    (det.cantidad * prod.precio) AS subtotal
FROM pedido p
CROSS JOIN LATERAL (
    SELECT 1 + floor(random()*4)::int AS n_items
) cnt
CROSS JOIN LATERAL generate_series(1, cnt.n_items) AS g(item_n)
CROSS JOIN LATERAL (
    SELECT
        1 + floor(random()*5)::int AS cantidad,
        1 + floor(random()*50000)::int AS prod_id
) det
JOIN producto prod ON prod.id_producto = det.prod_id;

-- ALTER TABLE detalle_pedido ENABLE TRIGGER ALL; -- si se deshabilito arriba

-- -----------------------------------------------------------------------------
-- 6. Recalculo de totales (compatibilidad con/sin triggers)
--    Si los triggers de objects.sql existen, este UPDATE es redundante.
--    Si no existen, garantiza que pedido.total = SUM(detalle.subtotal).
-- -----------------------------------------------------------------------------
UPDATE pedido p SET total = agg.s
FROM (
    SELECT pedido_id, SUM(subtotal)::numeric(10,2) AS s
    FROM detalle_pedido
    GROUP BY pedido_id
) agg
WHERE p.id_pedido = agg.pedido_id;

-- -----------------------------------------------------------------------------
-- 7. Sincronizacion de secuencias SERIAL (evita colisiones futuras)
-- -----------------------------------------------------------------------------
SELECT setval(pg_get_serial_sequence('categoria','id_categoria'), COALESCE((SELECT MAX(id_categoria) FROM categoria), 1), true);
SELECT setval(pg_get_serial_sequence('producto','id_producto'), COALESCE((SELECT MAX(id_producto) FROM producto), 1), true);
SELECT setval(pg_get_serial_sequence('usuario','id_usuario'), COALESCE((SELECT MAX(id_usuario) FROM usuario), 1), true);
SELECT setval(pg_get_serial_sequence('pedido','id_pedido'), COALESCE((SELECT MAX(id_pedido) FROM pedido), 1), true);
SELECT setval(pg_get_serial_sequence('detalle_pedido','id_detalle_pedido'), COALESCE((SELECT MAX(id_detalle_pedido) FROM detalle_pedido), 1), true);

COMMIT;

-- =============================================================================
-- Verificaciones post-carga (ejecutar despues del COMMIT):
-- SELECT 'categoria' AS tabla, count(*) FROM categoria UNION ALL
-- SELECT 'producto', count(*) FROM producto UNION ALL
-- SELECT 'usuario', count(*) FROM usuario UNION ALL
-- SELECT 'pedido', count(*) FROM pedido UNION ALL
-- SELECT 'detalle_pedido', count(*) FROM detalle_pedido;
-- -- CK disponible/stock: debe dar 0
-- SELECT count(*) AS violaciones_disponible FROM producto WHERE disponible AND stock=0;
-- -- CK subtotal: debe dar 0
-- SELECT count(*) AS violaciones_subtotal FROM detalle_pedido WHERE subtotal <> cantidad*precio_unitario;
-- -- Totales consistentes: debe dar 0
-- SELECT count(*) AS pedidos_descuadrados FROM pedido p
-- WHERE p.total <> COALESCE((SELECT SUM(subtotal) FROM detalle_pedido d WHERE d.pedido_id=p.id_pedido),0);
-- =============================================================================
