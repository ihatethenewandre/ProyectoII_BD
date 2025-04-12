import os, time, threading, statistics, psycopg2
from tabulate import tabulate

# Cadena de conexión: se lee de la variable de entorno o usa el valor por defecto
DSN = os.getenv(
    "PG_DSN",
    "dbname=proyecto_2 user=postgres password=jrss3105 host=localhost port=5432",
)

# ---------- 1. Operación concurrente que intenta insertar la reserva ----------
def reservar(seat_id: str, user_id: str, isolation: str, results: list):
    conn = psycopg2.connect(DSN)
    conn.set_session(isolation_level=isolation, autocommit=False)
    cur = conn.cursor()
    t0 = time.perf_counter()
    try:
        cur.execute(
            "INSERT INTO reservation (seat_id,user_id,event_id,status) "
            "VALUES (%s,%s,'00000000-0000-0000-0000-000000000001','CONFIRMED');",
            (seat_id, user_id),
        )
        conn.commit()
        results.append(("OK", (time.perf_counter() - t0) * 1000))
    except Exception:           # violación UNIQUE → rollback
        conn.rollback()
        results.append(("FAIL", (time.perf_counter() - t0) * 1000))
    finally:
        cur.close(); conn.close()

# ---------- 2. Primer asiento libre (bloqueo para evitar colisiones) ----------
def pick_available_seat(conn) -> tuple[str, str]:
    cur = conn.cursor()
    cur.execute(
        """
        SELECT s.seat_id,
               concat(sec.name,' fila ',s.row_label,' asiento ',s.seat_number)
        FROM seat s
        JOIN section sec USING (section_id)
        WHERE NOT EXISTS (SELECT 1 FROM reservation r WHERE r.seat_id = s.seat_id)
        ORDER BY sec.name, s.row_label, s.seat_number
        LIMIT 1
        FOR UPDATE SKIP LOCKED;        -- bloquea la fila y evita duplicados
        """
    )
    row = cur.fetchone()
    if not row:
        raise RuntimeError("No quedan asientos libres.")
    return row[0], row[1]

# ---------- 3. Menú de cantidad de hilos ----------
def menu_threads() -> int:
    opciones = { "1": 5, "2": 10, "3": 20, "4": 30 }
    print("\nUsuarios simultáneos")
    for k, v in opciones.items(): print(f"  {k}) {v}")
    return opciones.get(input("Seleccione opción ▶ ").strip(), 5)

# ---------- 4. Menú de nivel de aislamiento ----------
def menu_isolation() -> str:
    opciones = { "1": "READ COMMITTED", "2": "REPEATABLE READ", "3": "SERIALIZABLE" }
    print("\nNivel de aislamiento")
    for k, v in opciones.items(): print(f"  {k}) {v}")
    return opciones.get(input("Seleccione opción ▶ ").strip(), "READ COMMITTED")

# ---------- 5. Corre una simulación completa ----------
def run_simulation():
    with psycopg2.connect(DSN) as conn:
        seat_id, descr = pick_available_seat(conn)
        threads  = menu_threads()
        isolation = menu_isolation()
        cur = conn.cursor()
        cur.execute("SELECT user_id FROM app_user LIMIT %s;", (threads,))
        users = [r[0] for r in cur.fetchall()]          # 1 user_id por hilo

    results = []
    # Lanza un hilo por usuario
    workers = [threading.Thread(target=reservar, args=(seat_id,u,isolation,results))
               for u in users]
    for w in workers: w.start()
    for w in workers: w.join()

    ok   = sum(1 for r,_ in results if r=="OK")
    fail = len(results) - ok
    avg  = statistics.mean(t for _,t in results)

    # Guarda estadística de la corrida
    with psycopg2.connect(DSN) as c:
        c.cursor().execute(
            "INSERT INTO run_log(isolation_lvl,threads,seat_target,successes,failures,avg_ms)"
            "VALUES(%s,%s,%s,%s,%s,%s);",
            (isolation, threads, seat_id, ok, fail, avg),
        )

    # Muestra resumen
    print(
        "\nResumen",
        tabulate(
            [
                ["Asiento", descr],
                ["Usuarios", threads],
                ["Aislamiento", isolation],
                ["Éxitos", ok],
                ["Fallos", fail],
                ["Promedio (ms)", f"{avg:0.2f}"],
            ],
            tablefmt="github",
        ),
        sep="\n",
    )

# ---------- 6. Tabla de historiales ----------
def show_history():
    with psycopg2.connect(DSN) as c:
        cur = c.cursor()
        cur.execute(
            "SELECT run_id,started_at::timestamp(0),isolation_lvl,threads,successes,failures,avg_ms "
            "FROM run_log ORDER BY run_id DESC;"
        )
        rows = cur.fetchall()
    print(
        tabulate(
            rows,
            headers=["ID","Fecha","Nivel","Hilos","OK","FAIL","AVG(ms)"],
            tablefmt="github",
        )
    )

# ---------- 7. Menú principal ----------
def main():
    while True:
        print("\n" + "="*34, " SIMULADOR DE RESERVAS ", "="*34, sep="")
        print(" 1) Ejecutar nueva simulación")
        print(" 2) Ver historial de simulaciones")
        print(" 3) Salir")
        opcion = input("Seleccione ▶ ").strip()
        if opcion == "1":
            try: run_simulation()
            except RuntimeError as e: print(e)
        elif opcion == "2": show_history()
        elif opcion == "3": break
        else: print("Opción inválida.")

if __name__ == "__main__":
    main()