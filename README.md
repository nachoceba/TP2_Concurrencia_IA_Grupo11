# TP2 Concurrencia e IA — Grupo 11

## Integrantes (orden alfabético)

1. Ciro Cattáneo
2. Ignacio Ceballos
3. Santiago Copia
4. Franco Gagliardi
5. Emmanuel Miranda
6. Ramiro Quiroga

## Contexto

Proyecto correspondiente a la Tecnicatura en Programación de la UTN FRM — Asignatura de Bases de Datos II.

## Stack

- **Base de datos**: PostgreSQL 18.6 con ENUM types, soft deletes (`eliminado BOOLEAN`) y triggers
- **Esquema**: `schema.sql` (tipos → categoria → producto → usuario → pedido → detalle_pedido)
- **Frontend**: App servida en `localhost:8080`

## Estructura del proyecto

- `schema.sql` — DDL del esquema
- `data.sql` — DML de carga masiva sintética (categorías, productos, usuarios, pedidos y detalles)
- `indices.sql` — Índices de optimización y reescrituras de consultas (TP3)
- `AGENTS.md` — Instrucciones del proyecto para agentes
- `protocolo_seguridad.md` — Protocolo de trabajo con la base de datos
- `TP 2/` — TP2 Concurrencia e IA (`Parte 1/` integridad referencial, `Parte 2/` concurrencia y anomalías, `Parte 3/` lectura crítica)
- `TP 3/` — TP3 Optimización (capturas `EXPLAIN ANALYZE`, `2.2) Tabla de resultados.xlsx`, `3.4) Lectura crítica.xlsx`, `DUIA.md`, consultas y spec en `4)/`)

## Configuración del repositorio remoto

- **Remoto**: `origin` → `https://github.com/nachoceba/TP2_Concurrencia_IA_Grupo11.git`
- **Rama principal**: `main`
