# Protocolo de Seguridad para TP concurrencia e IA

## 1. Entorno de Trabajo
* **Motor de Base de Datos:** PostgreSQL 18.6
* **Base de Datos Principal:** `TP2_Concurrencia_IA_Grupo11`
* **Base de Datos de Trabajo (Copia):** `TP2_Concurrencia_IA_Grupo11`
* **Directorio Local de Respaldos:** `C:\Users\Nacho\Desktop\TP2_Concurrencia_IA_Grupo11`

---

## 2. Protocolo de Tres Pasos Adaptado

### Paso 1: Copia de Trabajo
Queda estrictamente prohibido ejecutar scripts generados por IA sobre la base principal `P2_Concurrencia_IA_Grupo11`.

Antes de probar cualquier cambio, creo un clon exacto de desarrollo en mi motor PostgreSQL local ejecutando desde la terminal:

```bash
# 1. Elimino la copia anterior si existiera
dropdb -U postgres P2_Concurrencia_IA_Grupo11 --if-exists

# 2. Creo la nueva copia de trabajo a partir de la base principal
createdb -U postgres -T P2_Concurrencia_IA_Grupo11 P2_Concurrencia_IA_Grupo11

### Paso 2: Transaccion
Todo script que escribe corre primero dentro de BEGIN;

ROLLBACK para inspeccionar el efecto (filas afectadas, mensajes) antes de confirmar
nada.

### Paso 3: Respaldo
pg_dump de la copia de trabajo antes de aplicar un cambio estructural
(ALTER, DROP, migración), para poder volver atrás sin depender del
ROLLBACK.