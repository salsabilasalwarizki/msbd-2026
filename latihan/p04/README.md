# Latihan Pertemuan 4 - SQL Lanjutan II

## Tujuan
Menerapkan view, materialized view, trigger audit, constraint, dan pola expand-contract pada PostgreSQL 17.

## Prasyarat
- Docker aktif
- PostgreSQL 17
- Basis data Pagila sudah terisi

## Menjalankan Setup
```powershell
Get-Content latihan/p04/q00_setup.sql | docker compose exec -T postgres psql -U msbd -d pagila