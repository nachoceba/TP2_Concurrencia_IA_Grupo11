-- =============================================================================
-- Orden de Inserción:
-- 1. Categorías (Limpia + Soft Delete)
-- 2. Productos (Vigentes + Sin ventas + Stock crítico + Soft Delete)
-- 3. Usuarios (Vigentes con roles ADMIN/USUARIO + Soft Delete)
-- 4. Pedidos directos (Historicos y vigentes en distintos meses/estados)
-- 5. Detalle de Pedidos directos (Dispara triggers de subtotal y total)
-- 6. Inserción vía Procedimiento Almacenado `sp_crear_pedido` (Prueba transaccional)
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- 1. CATEGORÍAS (categoria)
-- -----------------------------------------------------------------------------
-- Incluye categorías activas e inactivas (soft delete) para probar v_categorias_vigentes
INSERT INTO categoria (nombre, descripcion, eliminado) VALUES
('Pizzas', 'Pizza con masa madre', FALSE),
('Empanadas', 'Empanadas tradicionales de masa casera y rellenos abundantes', FALSE),
('Hamburguesas', 'Hamburguesas 100% carne vacuna y opciones veggie', FALSE),
('Bebidas', 'Gaseosas, aguas y jugos naturales', FALSE),
('Postres', 'Postres caseros y helados', FALSE),
('Promociones Especiales', 'Combos y ofertas descontinuadas de la temporada anterior', TRUE);


-- -----------------------------------------------------------------------------
-- 2. PRODUCTOS (producto)
-- -----------------------------------------------------------------------------

INSERT INTO producto (nombre, precio, descripcion, stock, imagen, disponible, categoria_id, eliminado) VALUES
-- Pizzas (categoria_id = 1)
('Muzzarella', 4500.00, 'Salsa de tomate casera, queso muzzarella y orégano', 50, 'muzza.jpg', TRUE, 1, FALSE),
('Especial de Jamón y Morrones', 5800.00, 'Muzzarella, jamón cocido y morrones asados', 35, 'especial.jpg', TRUE, 1, FALSE),
('Fugazzeta Rellena', 6200.00, 'Rellena de muzzarella con cebolla y aceite de oliva', 20, 'fugazzeta.jpg', TRUE, 1, FALSE),
('Napolitana', 5200.00, 'Muzzarella, rodajas de tomate, ajo y albahaca', 15, 'napo.jpg', TRUE, 1, FALSE),

-- Empanadas (categoria_id = 2)
('Empanada Carne Cuchillo', 950.00, 'Carne cortada a cuchillo, cebolla, huevo y especias', 120, 'emp_carne.jpg', TRUE, 2, FALSE),
('Empanada Jamón y Queso', 900.00, 'Jamón cocido y queso muzzarella', 100, 'emp_jq.jpg', TRUE, 2, FALSE),
('Empanada Roquefort', 950.00, 'Queso azul, muzzarella y cebolla', 40, 'emp_roque.jpg', TRUE, 2, FALSE),

-- Hamburguesas (categoria_id = 3)
('Burger Simple Cheese', 6500.00, 'Medallón de 180g, cheddar y cheddar ', 30, 'burger_simple.jpg', TRUE, 3, FALSE),
('Burger Doble Bacon', 8200.00, 'Doble medallón de 180g, doble cheddar y bacon', 25, 'burger_doble.jpg', TRUE, 3, FALSE),
('Burger Veggie NotMeat', 7100.00, 'Medallón vegetal, lechuga, tomate y aderezo especial', 15, 'burger_veggie.jpg', TRUE, 3, FALSE),

-- Bebidas (categoria_id = 4)
('Coca-Cola Original 1.5L', 2200.00, 'Gaseosa Coca-Cola botella 1.5 litros', 80, 'coca_15.jpg', TRUE, 4, FALSE),
('Cerveza Patagonia 730ml', 3500.00, 'Cerveza artesanal Amber Ale', 45, 'cerveza_patagonia.jpg', TRUE, 4, FALSE),
('Agua Mineral 500ml', 1200.00, 'Agua mineral sin gas', 100, 'agua_500.jpg', TRUE, 4, FALSE),

-- Postres (categoria_id = 5) - *Uno sin stock y otro sin ventas previstas*
('Flan Casero', 2800.00, 'Flan con dulce de leche y crema', 12, 'flan.jpg', TRUE, 5, FALSE),
('Volcán de Chocolate', 3400.00, 'Bizcochuelo con corazón de chocolate fundido', 0, 'volcan.jpg', FALSE, 5, FALSE), -- Sin stock
('Tarta de Frutilla', 3200.00, 'Tarta individual con crema pastelera y frutillas', 10, 'tarta_frutilla.jpg', TRUE, 5, FALSE), -- Producto Sin Ventas (Para Consulta E)

-- Producto Eliminado (soft delete)
('Pizza de Ananá (Hawaiana)', 4800.00, 'Muzzarella, jamón y ananá en almíbar', 0, 'hawaiana.jpg', FALSE, 1, TRUE);


-- -----------------------------------------------------------------------------
-- 3. USUARIOS (usuario)
-- -----------------------------------------------------------------------------

INSERT INTO usuario (nombre, apellido, mail, celular, contrasena, rol, eliminado) VALUES
('Milton', 'Gimenez', 'milton.gimenez@email.com', '2614123456', '$2a$10$e83U...hash1', 'USUARIO', FALSE),
('Ana', 'Garis', 'ana.garis@email.com', '2615987654', '$2a$10$f94V...hash2', 'USUARIO', FALSE),
('Carlos', 'Mendoza', 'carlos.mendoza@email.com', '2613112233', '$2a$10$g05W...hash3', 'ADMIN', FALSE),
('Lucía', 'Fernández', 'lucia.f@email.com', '2616445566', '$2a$10$h16X...hash4', 'USUARIO', FALSE),
('Roberto', 'Gómez', 'roberto.g@email.com', '2612778899', '$2a$10$i27Y...hash5', 'USUARIO', FALSE),
('Mariano', 'López', 'mariano.lopez@email.com', '2618990011', '$2a$10$j38Z...hash6', 'USUARIO', TRUE); -- Usuario eliminado


-- -----------------------------------------------------------------------------
-- 4. PEDIDOS (pedido)
-- -----------------------------------------------------------------------------

-- El campo total se inicializa en 0 y será actualizado automáticamente
-- por el trigger `trg_total_ins` cuando se inserten los detalles.

INSERT INTO pedido (fecha, estado, total, forma_pago, usuario_id, eliminado) VALUES
('2026-06-15', 'TERMINADO', 0.00, 'EFECTIVO', 1, FALSE),       -- Pedido 1 (Junio) - Milton Gimenez
('2026-06-20', 'TERMINADO', 0.00, 'TARJETA', 2, FALSE),        -- Pedido 2 (Junio) - Ana Garis
('2026-07-05', 'TERMINADO', 0.00, 'TRANSFERENCIA', 1, FALSE),  -- Pedido 3 (Julio) - Milton Gimenez
('2026-07-18', 'TERMINADO', 0.00, 'TARJETA', 4, FALSE),        -- Pedido 4 (Julio) - Lucía Fernández
('2026-08-01', 'CONFIRMADO', 0.00, 'EFECTIVO', 2, FALSE),       -- Pedido 5 (Agosto) - Ana Garis
('2026-08-10', 'PENDIENTE', 0.00, 'TRANSFERENCIA', 5, FALSE),  -- Pedido 6 (Agosto) - Roberto Gómez
('2026-08-12', 'CANCELADO', 0.00, 'EFECTIVO', 4, FALSE);        -- Pedido 7 (Agosto) - Lucía Fernández


-- -----------------------------------------------------------------------------
-- 5. DETALLE DE PEDIDOS (detalle_pedido)
-- -----------------------------------------------------------------------------
-- Al insertar los detalles, el trigger `trg_subtotal` autocalculará:
--   subtotal = cantidad * precio_unitario (o congela el precio del producto)
-- Y el trigger `trg_total_ins` recalcula automaticamente el total del pedido.

-- Detalles del Pedido 1 (Milton Gimenez - Junio)
INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(1, 1, 2, 4500.00), -- 2x Muzzarella Clásica ($9,000)
(1, 11, 2, 2200.00); -- 2x Coca-Cola ($4,400) -> Total Pedido 1: $13,400

-- Detalles del Pedido 2 (Ana Garis - Junio)
INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(2, 9, 2, 8200.00), -- 2x Burger Doble Bacon ($16,400)
(2, 12, 2, 3500.00), -- 2x Cerveza Patagonia ($7,000)
(2, 14, 2, 2800.00); -- 2x Flan Casero ($5,600) -> Total Pedido 2: $29,000

-- Detalles del Pedido 3 (Milton Gimenez - Julio)
INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(3, 5, 12, 950.00), -- 12x Empanada Carne Cuchillo ($11,400)
(3, 6, 6, 900.00),  -- 6x Empanada Jamón y Queso ($5,400)
(3, 11, 1, 2200.00); -- 1x Coca-Cola ($2,200) -> Total Pedido 3: $19,000

-- Detalles del Pedido 4 (Lucía Fernández - Julio)
INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(4, 3, 1, 6200.00), -- 1x Fugazzeta Rellena ($6,200)
(4, 11, 1, 2200.00); -- 1x Coca-Cola ($2,200) -> Total Pedido 4: $8,400

-- Detalles del Pedido 5 (Ana Garis - Agosto)
INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(5, 2, 1, 5800.00), -- 1x Especial Jamón y Morrones ($5,800)
(5, 5, 6, 950.00),  -- 6x Empanada Carne Cuchillo ($5,700)
(5, 13, 2, 1200.00); -- 2x Agua Mineral ($2,400) -> Total Pedido 5: $13,900

-- Detalles del Pedido 6 (Roberto Gómez - Agosto)
INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(6, 8, 1, 6500.00), -- 1x Burger Simple Cheese ($6,500)
(6, 11, 1, 2200.00); -- 1x Coca-Cola ($2,200) -> Total Pedido 6: $8,700

-- Detalles del Pedido 7 (Lucía Fernández - Cancelado)
INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(7, 10, 1, 7100.00); -- 1x Burger Veggie ($7,100) -> Total Pedido 7: $7,100

COMMIT;


