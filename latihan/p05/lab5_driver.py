"""
Lab 5 Driver - psycopg 3 examples
Diminta: mendemonstrasikan parameter binding, injection test, pool, dan rollback.
Dipilih: psycopg 3 dengan parameter binding %s untuk keamanan dari injeksi SQL.
Alternatif: f-string untuk merangkai SQL; tidak dipilih karena rawan injeksi.
"""

import os
import psycopg
from psycopg import sql
from psycopg_pool import ConnectionPool

# DSN dari environment variable atau default
DSN = os.environ.get("DSN", "postgresql://msbd:msbd2026@localhost:5432/pagila")


# ============================================================
# Q10: SELECT berparameter
# ============================================================
def q10_select_berparameter():
    print("\n=== Q10: SELECT berparameter ===")
    with psycopg.connect(DSN) as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT customer_id, first_name, last_name "
                "FROM public.customer WHERE customer_id = %s",
                (1,)
            )
            row = cur.fetchone()
            print(f"Customer: {row}")


# ============================================================
# Q11: Uji Injeksi
# ============================================================
def q11_uji_injeksi():
    print("\n=== Q11: Uji Injeksi ===")
    payload = "SMITH' OR '1'='1"
    
    # Versi f-string (JANGAN DIJALANKAN - berbahaya!)
    sql_injection = f"SELECT customer_id FROM public.customer WHERE last_name = '{payload}'"
    print(f"[BAHAYA] SQL injeksi (tidak dijalankan): {sql_injection}")
    
    # Versi berparameter (AMAN)
    with psycopg.connect(DSN) as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT customer_id FROM public.customer WHERE last_name = %s",
                (payload,)
            )
            rows = cur.fetchall()
            print(f"[AMAN] Hasil parameter binding: {rows} (harus kosong)")


# ============================================================
# Q12: Identifier dan allow-list
# ============================================================
def q12_identifier_allowlist():
    print("\n=== Q12: Identifier dan allow-list ===")
    
    # Coba kirim nama kolom sebagai parameter nilai (GAGAL)
    try:
        with psycopg.connect(DSN) as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT customer_id, first_name FROM public.customer ORDER BY %s",
                    ("last_name",)
                )
                print("Ini tidak akan tercapai")
    except Exception as e:
        print(f"[GAGAL] Error saat ORDER BY pakai parameter nilai: {type(e).__name__}")
    
    # Perbaikan dengan sql.Identifier dan allow-list
    allowed_columns = {"customer_id", "first_name", "last_name", "email"}
    order_col = "last_name"
    
    if order_col not in allowed_columns:
        raise ValueError(f"Kolom {order_col} tidak diizinkan")
    
    with psycopg.connect(DSN) as conn:
        with conn.cursor() as cur:
            query = sql.SQL(
                "SELECT customer_id, first_name FROM public.customer ORDER BY {}"
            ).format(sql.Identifier(order_col))
            cur.execute(query)
            rows = cur.fetchall()[:3]
            print(f"[BERHASIL] Hasil dengan sql.Identifier: {rows}")


# ============================================================
# Q13: Rollback dari aplikasi
# ============================================================
def q13_rollback_dari_aplikasi():
    print("\n=== Q13: Rollback dari aplikasi ===")
    
    # Hitung sebelum
    with psycopg.connect(DSN) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT count(*) FROM lab5.rental_tx")
            count_before = cur.fetchone()[0]
            print(f"Count sebelum: {count_before}")
    
    # Coba panggil procedure lalu raise exception
    try:
        with psycopg.connect(DSN) as conn:
            with conn.cursor() as cur:
                # Casting eksplisit agar PostgreSQL cocok dengan signature procedure
                cur.execute(
                    "CALL lab5.process_rental(%s::integer, %s::integer, %s::integer, %s::numeric)",
                    (5, 5, 1, 4.99)
                )
                raise RuntimeError("Gagal di tengah alur - simulasi error aplikasi")
    except RuntimeError as e:
        print(f"Exception: {e}")
    
    # Hitung sesudah (harus SAMA karena rollback otomatis)
    with psycopg.connect(DSN) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT count(*) FROM lab5.rental_tx")
            count_after = cur.fetchone()[0]
            print(f"Count sesudah: {count_after}")
            print(f"Rollback berhasil: {count_before == count_after}")


# ============================================================
# Q14: ConnectionPool
# ============================================================
def q14_connection_pool():
    print("\n=== Q14: ConnectionPool ===")
    
    with ConnectionPool(DSN, min_size=2, max_size=2) as pool:
        # Jalankan 5 permintaan berurutan
        for i in range(5):
            with pool.connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT %s AS request_number", (i + 1,))
                    result = cur.fetchone()[0]
                    print(f"Request {result} selesai")
        
        # Tampilkan statistik pool
        stats = pool.get_stats()
        print(f"\nPool stats: {stats}")


# ============================================================
# Main
# ============================================================
if __name__ == "__main__":
    print("=== Memulai Lab 5 Driver (psycopg 3) ===")
    q10_select_berparameter()
    q11_uji_injeksi()
    q12_identifier_allowlist()
    q13_rollback_dari_aplikasi()
    q14_connection_pool()
    print("\n=== Semua Q10-Q14 selesai ===")