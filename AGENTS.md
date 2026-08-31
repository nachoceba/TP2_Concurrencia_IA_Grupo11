# TP2 Concurrencia IA Grupo 11

## Stack
- **Database**: PostgreSQL with ENUM types, soft deletes (`eliminado BOOLEAN`), and triggers
- **Frontend**: Chrome-based app served at `localhost:8080` (see `.vscode/launch.json`)
- **Schema entrypoint**: `schema.sql` (creates types → categoria → producto → usuario → pedido → detalle_pedido)
- **Data entrypoint**: `data.sql` (seed data including trigger-driven totals)

## Architecture Notes
- Soft delete pattern: every table has an `eliminado` boolean column (`TRUE` = logically deleted)
- `pedido.total` and `detalle_pedido.subtotal` are computed by triggers (see `objects.sql - Integrante 3`)
- ENUM types must be created before tables that reference them: `rol_usuario`, `estado_pedido`, `forma_pago`
- `precio_unitario` in `detalle_pedido` freezes the product price at sale time (does not reference `producto.precio`)

## Data Seeding Order (critical)
1. `schema.sql` must run first
2. `data.sql` inserts in order: categorías → productos → usuarios → pedidos → detalles → stored procedure `sp_crear_pedido`
3. Detalle insertions fire `trg_subtotal` and `trg_total_ins` triggers

## Known Files
- `schema.sql` — DDL
- `data.sql` — DML seed data
- `.vscode/launch.json` — Chrome debug config pointing to `http://localhost:8080`
- `objects.sql` (referenced in schema comments, not yet present in repo) — contains trigger implementations for Integrante 3

## Safety rules
- Antes de proponer o ejecutar scripts sql, consulta y respeta el protocolo definido en `protocolo_seguridad.md`
