"""
Lab 5 API - FastAPI endpoint
Diminta: endpoint POST /rentals yang memanggil procedure.
Dipilih: FastAPI dengan Pydantic validation dan dependency generator.
Alternatif: Flask; tidak dipilih karena FastAPI lebih modern dengan auto-docs.
"""

import os
from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel, Field
import psycopg
from psycopg_pool import ConnectionPool

app = FastAPI(title="Lab 5 API")

# Gunakan postgresql+psycopg:// agar konsisten dengan psycopg 3
DSN = os.environ.get("DSN", "postgresql+psycopg://msbd:msbd2026@localhost:5432/pagila")
pool = ConnectionPool(DSN, min_size=2, max_size=5)


# ============================================================
# Q21: Dependency Koneksi (Generator function, tanpa @contextmanager)
# ============================================================
def get_conn():
    with pool.connection() as conn:
        yield conn


# ============================================================
# Request Model (Validasi Pydantic)
# ============================================================
class RentalRequest(BaseModel):
    customer_id: int = Field(gt=0)
    inventory_id: int = Field(gt=0)
    staff_id: int = Field(gt=0)
    amount: float = Field(gt=0)  # Validasi: harus positif (> 0)


# ============================================================
# Q22 & Q23: POST /rentals
# ============================================================
@app.post("/rentals", status_code=201)
def create_rental(request: RentalRequest, conn=Depends(get_conn)):
    try:
        with conn.cursor() as cur:
            # PERBAIKAN: Tambahkan casting tipe data eksplisit
            cur.execute(
                "CALL lab5.process_rental(%s::integer, %s::integer, %s::integer, %s::numeric)",
                (request.customer_id, request.inventory_id, request.staff_id, request.amount)
            )
            cur.execute("SELECT lastval()")
            rental_id = cur.fetchone()[0]
            return {"rental_id": rental_id, "status": "created"}
    except psycopg.errors.CheckViolation:
        # Ini akan menangkap error dari domain positive_amount jika lolos validasi Pydantic
        raise HTTPException(status_code=422, detail="Nilai amount harus positif")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# Q24: POST /rentals-safe (Menangani Foreign Key Violation)
# ============================================================
@app.post("/rentals-safe", status_code=201)
def create_rental_safe(request: RentalRequest, conn=Depends(get_conn)):
    try:
        with conn.cursor() as cur:
            # PERBAIKAN: Tambahkan casting tipe data eksplisit
            cur.execute(
                "CALL lab5.process_rental_safe(%s::integer, %s::integer, %s::integer, %s::numeric)",
                (request.customer_id, request.inventory_id, request.staff_id, request.amount)
            )
            cur.execute("SELECT lastval()")
            rental_id = cur.fetchone()[0]
            return {"rental_id": rental_id, "status": "created"}
    except psycopg.errors.ForeignKeyViolation:
        raise HTTPException(status_code=409, detail="Data referensi tidak valid")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# Health Check
# ============================================================
@app.get("/health")
def health_check():
    return {"status": "ok"}