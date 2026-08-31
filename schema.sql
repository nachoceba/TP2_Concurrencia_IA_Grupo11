-- =============================================================================
-- Orden de creación:
--   1. Tipos ENUM (rol_usuario, estado_pedido, forma_pago)
--   2. Tabla categoria
--   3. Tabla producto
--   4. Tabla usuario
--   5. Tabla pedido
--   6. Tabla detalle_pedido

BEGIN;

-- -----------------------------------------------------------------------------
-- 0. TIPOS ENUM
-- -----------------------------------------------------------------------------

CREATE TYPE rol_usuario AS ENUM ('ADMIN', 'USUARIO');

CREATE TYPE estado_pedido AS ENUM ('PENDIENTE', 'CONFIRMADO', 'TERMINADO', 'CANCELADO');

CREATE TYPE forma_pago AS ENUM ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA');


-- -----------------------------------------------------------------------------
-- 1. CATEGORIA
-- -----------------------------------------------------------------------------

CREATE TABLE categoria (
    id_categoria    SERIAL PRIMARY KEY,
    nombre          VARCHAR(100)    NOT NULL,
    descripcion     VARCHAR(255),
    eliminado       BOOLEAN         NOT NULL DEFAULT FALSE
);

COMMENT ON COLUMN categoria.eliminado IS 'Soft delete: TRUE = categoria dada de baja logicamente';


-- -----------------------------------------------------------------------------
-- 2. PRODUCTO
-- -----------------------------------------------------------------------------

CREATE TABLE producto (
    id_producto     SERIAL PRIMARY KEY,
    nombre          VARCHAR(150)    NOT NULL,
    precio          NUMERIC(10,2)   NOT NULL CHECK (precio >= 0),
    descripcion     VARCHAR(255),
    stock           INTEGER         NOT NULL DEFAULT 0 CHECK (stock >= 0),
    imagen          VARCHAR(255),
    disponible      BOOLEAN         NOT NULL DEFAULT TRUE,
    categoria_id    INTEGER         NOT NULL REFERENCES categoria(id_categoria),
    eliminado       BOOLEAN         NOT NULL DEFAULT FALSE
);

COMMENT ON COLUMN producto.eliminado IS 'Soft delete: TRUE = producto dado de baja logicamente';
COMMENT ON COLUMN producto.disponible IS 'Disponibilidad comercial (distinto de eliminado): permite ocultar un producto sin stock sin darlo de baja';

CREATE INDEX idx_producto_categoria_id ON producto(categoria_id);


-- -----------------------------------------------------------------------------
-- 3. USUARIO
-- -----------------------------------------------------------------------------

CREATE TABLE usuario (
    id_usuario      SERIAL PRIMARY KEY,
    nombre          VARCHAR(100)    NOT NULL,
    apellido        VARCHAR(100)    NOT NULL,
    mail            VARCHAR(150)    NOT NULL UNIQUE,
    celular         VARCHAR(20),
    contrasena      VARCHAR(255)    NOT NULL,
    rol             rol_usuario     NOT NULL DEFAULT 'USUARIO',
    eliminado       BOOLEAN         NOT NULL DEFAULT FALSE
);

COMMENT ON COLUMN usuario.contrasena IS 'Hash de la contrasena (nunca texto plano)';
COMMENT ON COLUMN usuario.eliminado IS 'Soft delete: TRUE = usuario dado de baja logicamente';


-- -----------------------------------------------------------------------------
-- 4. PEDIDO
-- -----------------------------------------------------------------------------

CREATE TABLE pedido (
    id_pedido       SERIAL PRIMARY KEY,
    fecha           DATE            NOT NULL DEFAULT CURRENT_DATE,
    estado          estado_pedido   NOT NULL DEFAULT 'PENDIENTE',
    total           NUMERIC(10,2)   NOT NULL DEFAULT 0 CHECK (total >= 0),
    forma_pago      forma_pago      NOT NULL,
    usuario_id      INTEGER         NOT NULL REFERENCES usuario(id_usuario),
    eliminado       BOOLEAN         NOT NULL DEFAULT FALSE
);

COMMENT ON COLUMN pedido.total IS 'Calculado automaticamente por trigger a partir de detalle_pedido (ver objects.sql - Integrante 3)';
COMMENT ON COLUMN pedido.eliminado IS 'Soft delete: TRUE = pedido dado de baja logicamente';

CREATE INDEX idx_pedido_usuario_id ON pedido(usuario_id);
CREATE INDEX idx_pedido_fecha ON pedido(fecha);
CREATE INDEX idx_pedido_estado ON pedido(estado);


-- -----------------------------------------------------------------------------
-- 5. DETALLE_PEDIDO
-- -----------------------------------------------------------------------------

CREATE TABLE detalle_pedido (
    id_detalle_pedido  SERIAL          PRIMARY KEY,
    pedido_id          INTEGER         NOT NULL REFERENCES pedido(id_pedido),
    producto_id        INTEGER         NOT NULL REFERENCES producto(id_producto),
    cantidad           INTEGER         NOT NULL CHECK (cantidad > 0),
    precio_unitario    NUMERIC(10,2)   NOT NULL CHECK (precio_unitario >= 0),
    subtotal           NUMERIC(10,2)   NOT NULL DEFAULT 0 CHECK (subtotal >= 0)
);

COMMENT ON COLUMN detalle_pedido.precio_unitario IS 'Precio congelado del producto al momento de la venta (no referencia producto.precio directamente)';
COMMENT ON COLUMN detalle_pedido.subtotal IS 'Calculado automaticamente por trigger: cantidad * precio_unitario (ver objects.sql - Integrante 3)';

CREATE INDEX idx_detalle_pedido_pedido_id ON detalle_pedido(pedido_id);
CREATE INDEX idx_detalle_pedido_producto_id ON detalle_pedido(producto_id);

COMMIT;
