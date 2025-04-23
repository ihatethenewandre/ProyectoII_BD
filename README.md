# Proyecto II – Simulaciones de Reservas Concurrentes

Este proyecto demuestra el manejo de concurrencia y transacciones en una base de datos PostgreSQL. Utiliza hilos en Python para simular múltiples usuarios intentando reservar los mismos asientos en un evento.

---

## Contenido del Repositorio

- **`ddl.sql`**  
  Define la estructura de la base de datos (tablas, llaves primarias, llaves foráneas y restricciones).
- **`data.sql`**  
  Carga datos de ejemplo (usuarios, evento, secciones y asientos). Incluye algunas reservas iniciales.
- **`simulador.py`**  
  Script principal que realiza las simulaciones concurrentes, permitiendo seleccionar:
  - Cantidad de usuarios simultáneos.  
  - Nivel de aislamiento de las transacciones (READ COMMITTED, REPEATABLE READ, SERIALIZABLE).  
  - Se registra el resultado de cada corrida en la tabla `run_log`.
- **`venv/`**  
  Carpeta con el entorno virtual de Python (opcional). Contiene las librerías `psycopg2-binary` y `tabulate`.  

---

## Guía de Uso

### 1. Prerrequisitos

- **PostgreSQL** 
- **Python** 
- **Extensión** `uuid-ossp` activada en la base de datos.

### 2. Creación de la Base de Datos

1. **Crear una base** llamada `evento_db`:
   ```sql
   CREATE DATABASE evento_db;

2. **Conectarse a** `evento_db` desde pgAdmin:

3. **Ejecutar** `ddl.sql` para crear las tablas.

4. **Ejecutar** `data.sql` para cargar los datos de prueba.

### 3. Configuración del Entorno Python

1. **Activar** en Windows Powershell:
   ```powershell
   .\venv\Scripts\activate

### 4. Ejecución del Simulador

1. **Ejecutar** el script Python:
   ```cmd
   python simulador.py
