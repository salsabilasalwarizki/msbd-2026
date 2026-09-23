# Latihan Pertemuan 5: Dari Procedure sampai Endpoint

Latihan ini mencakup pembangunan alur utuh dari procedure PostgreSQL hingga endpoint HTTP menggunakan PL/pgSQL, psycopg 3, Connection Pool, SQLAlchemy (ORM), dan FastAPI.

## Prasyarat

Pastikan Anda telah menginstal:
- **Docker Desktop** (berjalan aktif)
- **Python 3.10** atau lebih baru
- **Git** (untuk manajemen versi)
- **PostgreSQL 17** (berjalan di dalam Docker container `postgres` pada port 5432)

---

## 1. Persiapan Lingkungan (Setup)

Buka terminal PowerShell di folder root proyek (`D:\Documents\msbd-2026`), lalu jalankan perintah berikut secara berurutan:

### 1.1 Buat dan Aktifkan Virtual Environment
```powershell
# Buat virtual environment
python -m venv .venv

# Aktifkan virtual environment (PowerShell)
.venv\Scripts\Activate.ps1
```
*(Pastikan muncul tulisan `(.venv)` di awal prompt terminal)*

### 1.2 Instal Dependensi Python
```powershell
pip install "psycopg[binary,pool]==3.2.*" "sqlalchemy==2.0.*" "fastapi==0.115.*" "uvicorn==0.32.*" "pydantic==2.*"
```

### 1.3 Atur Variabel Lingkungan (DSN)
**PENTING:** Gunakan `postgresql+psycopg://` agar SQLAlchemy menggunakan driver psycopg 3, bukan mencari psycopg2.
```powershell
$env:DSN = "postgresql+psycopg://msbd:msbd2026@localhost:5432/pagila"
```

### 1.4 Setup Database (Skema lab5)
Pastikan Docker berjalan, lalu jalankan script setup:
```powershell
Get-Content latihan/p05/q00_setup.sql | docker compose exec -T postgres psql -U msbd -d pagila
```
*Verifikasi:* Pastikan tidak ada pesan error dan skema `lab5` beserta tabel `rental_tx` dan `payment_tx` berhasil dibuat.

---

## 2. Menjalankan Skrip Python

Pastikan virtual environment (`.venv`) masih aktif.

### 2.1 Menjalankan Driver (psycopg 3)
Menguji parameter binding, pencegahan injeksi SQL, connection pool, dan rollback.
```powershell
python latihan/p05/lab5_driver.py
```

### 2.2 Menjalankan ORM (SQLAlchemy 2.0)
Membuktikan masalah N+1 dan solusinya menggunakan `selectinload` dan `joinedload`.
```powershell
python latihan/p05/lab5_orm.py
```
*(Catatan: Tambahkan `echo=True` di `create_engine` sudah diaktifkan untuk melihat log query SQL di terminal).*

---

##  3. Menjalankan API (FastAPI)

Jalankan server pengembangan FastAPI di terminal terpisah (pastikan `.venv` aktif):
```powershell
uvicorn latihan.p05.lab5_api:app --reload --port 8000
```
Server akan berjalan di: **http://localhost:8000**  
Dokumentasi API otomatis (Swagger UI) tersedia di: **http://localhost:8000/docs**

---

##  4. Pengujian Endpoint (Testing)

Di Windows PowerShell, perintah `curl` bawaan adalah alias dari `Invoke-WebRequest` yang sering error dengan sintaks Linux. Gunakan salah satu dari dua metode di bawah ini:

### Metode A: Menggunakan `curl.exe` (Asli)
*Perhatikan penggunaan tanda kutip yang di-escape (`\"`)*

**Q22: Sukses Membuat Rental (HTTP 201)**
```powershell
curl.exe -X POST http://localhost:8000/rentals -H "Content-Type: application/json" -d '{\"customer_id\":1,\"inventory_id\":1,\"staff_id\":1,\"amount\":4.99}'
```

**Q23: Validasi Gagal - Nilai Negatif (HTTP 422)**
```powershell
curl.exe -X POST http://localhost:8000/rentals -H "Content-Type: application/json" -d '{\"customer_id\":1,\"inventory_id\":1,\"staff_id\":1,\"amount\":-4.99}'
```

**Q24: Data Referensi Tidak Ada (HTTP 409)**
```powershell
curl.exe -X POST http://localhost:8000/rentals-safe -H "Content-Type: application/json" -d '{\"customer_id\":1,\"inventory_id\":999999,\"staff_id\":1,\"amount\":4.99}'
```

### Metode B: Menggunakan Native PowerShell (Lebih Stabil)
**Q22: Sukses Membuat Rental**
```powershell
$body = @{customer_id=1; inventory_id=1; staff_id=1; amount=4.99} | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:8000/rentals" -Method Post -Body $body -ContentType "application/json"
```

**Q23: Validasi Gagal - Nilai Negatif**
```powershell
$body = @{customer_id=1; inventory_id=1; staff_id=1; amount=-4.99} | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:8000/rentals" -Method Post -Body $body -ContentType "application/json"
```

**Q24: Data Referensi Tidak Ada**
```powershell
$body = @{customer_id=1; inventory_id=999999; staff_id=1; amount=4.99} | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:8000/rentals-safe" -Method Post -Body $body -ContentType "application/json"
```

---

##  Troubleshooting

| Gejala / Error | Penyebab | Solusi |
| :--- | :--- | :--- |
| `ModuleNotFoundError: No module named 'psycopg2'` | SQLAlchemy default mencari `psycopg2`. | Pastikan DSN menggunakan `postgresql+psycopg://` (bukan `postgresql://`). |
| `procedure lab5.process_rental(...) does not exist` | Tipe data parameter tidak cocok atau procedure belum dibuat. | Pastikan `q02_process_rental.sql` sudah dijalankan, dan kode Python menggunakan casting eksplisit (`%s::integer`, `%s::numeric`). |
| `'_GeneratorContextManager' object has no attribute 'cursor'` | Menggunakan `@contextmanager` di dependency FastAPI. | Hapus `@contextmanager`, gunakan fungsi generator biasa dengan `yield conn`. |
| Error `curl` di PowerShell (`Cannot bind parameter 'Headers'`) | PowerShell mengartikan `curl` sebagai `Invoke-WebRequest`. | Gunakan `curl.exe` (dengan `.exe`) atau gunakan sintaks `Invoke-RestMethod`. |
| `Connection refused` pada port 5432 | Container PostgreSQL belum berjalan. | Jalankan `docker compose up -d` dan cek dengan `docker compose ps`. |

---

## Anggota Kelompok

| Nama | NIM | Kontribusi Utama |
| :--- | :--- | :--- |
| Salsabila Salwa Rizki | 251402123 | Q1-Q5, Refleksi A, Setup Database |
| Nadia Stevany Br Situmorang | 251402073 | Q6-Q9, Refleksi B (Tipe Data) |
| Sina Mahdi Sitanggang | 251402008 | Q10-Q15, Refleksi C, `lab5_driver.py` |
| Jesqueen Maria Purba | 251402099 | Q16-Q24, Refleksi D-E, R1, `lab5_orm.py`, `lab5_api.py` |
