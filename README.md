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
- `AGENTS.md` — Instrucciones del proyecto para agentes
- `protocolo_seguridad.md` — Protocolo de trabajo con la base de datos
- `Parte 1/` — Integridad referencial y restricciones
- `Parte 2/` — Informe de concurrencia y anomalías en PostgreSQL
- `Parte 3/` — Ejercicio de lectura crítica de scripts SQL

## Configuración del repositorio remoto

- **Remoto**: `origin` → `https://github.com/nachoceba/TP2_Concurrencia_IA_Grupo11.git`
- **Rama principal**: `main`
