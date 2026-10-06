# Hasil Pengukuran Latihan 6

## Kondisi Uji
- PostgreSQL: 17.11
- Data: 2.000.000 baris di lab6.event_log
- Parallel workers: 0 (disabled)
- Pengulangan: 3 kali per query

## Tabel Perbandingan Query

| Query | Deskripsi | Tercepat (ms) | Median (ms) | Buffers (hit+read) | Catatan |
|-------|-----------|---------------|-------------|-------------------|---------|
| Q7 Baseline | Seq Scan tanpa index | 385.440 | 396.932 | 10310+48261 | Sort Method: quicksort 26kB |
| Q8 Urutan Salah | Index (terjadi_pada, customer_id) | 49.324 | 57.011 | 3825 | Index Scan Backward |
| Q9 Urutan Benar | Index (customer_id, terjadi_pada DESC) | 0.131 | 0.136 | 18 | Index Scan, no Sort |
| Q13 Expression | lower(email) dengan index | 1.159 | - | 4 | vs Seq Scan 740ms |
| Q14 Covering | Index Only Scan sebelum VACUUM | 1.157 | - | 5 | Heap Fetches: 0 |
| Q14 Covering | Index Only Scan setelah VACUUM | 0.073 | - | 5 | 15.8x lebih cepat |
| Q17 GIN JSONB | payload @> '{"promo": true}' | 414.933 | 421.822 | 58589 | 80000 rows |
| Q18 GIN Array | tags @> ARRAY['kanal:1'] | 1396.806 | - | 58644 | Lebih lambat dari Seq Scan |
| Q18 Seq Scan | tags tanpa GIN | 1281.320 | - | 58575 | 500000 rows |
| Q20 B-Tree | Range 7 hari | 37.103 | - | 1499 | 46523 rows |
| Q20 BRIN/Seq | Range 7 hari (paksa) | 542.332 | - | 58568 | B-Tree 14.6x lebih cepat |
| Q22 SUKSES | status = 'SUKSES' (84%) | 847.292 | - | 58568 | Seq Scan |
| Q22 GAGAL | status = 'GAGAL' (2%) | 232.397 | - | 40092 | Index Scan |
| Q24 SUKSES | random_page_cost=1.1 | 4102.233 | - | 58568 | Tetap Seq Scan |
| Q24 GAGAL | random_page_cost=1.1 | 1507.032 | - | 40092 | Tetap Index Scan |
| Q25 Extended | wilayah & kota stats | 1421.981 | - | 58568 | Estimasi: 42999, Aktual: 44444 |
| Q27 INSERT | Tanpa index (200k rows) | 2098.258 | - | - | 2.1 detik |
| Q27 INSERT | Dengan 5 index (200k rows) | 17103.549 | - | - | 17.1 detik (715% lebih lambat) |

## Tabel Ukuran Index

| Index Name | Ukuran | Tipe | Keterangan |
|------------|--------|------|------------|
| ev_benar_idx | 60 MB | B-Tree | (customer_id, terjadi_pada DESC) |
| ev_salah_idx | 60 MB | B-Tree | (terjadi_pada, customer_id) |
| ev_gagal_idx | 896 kB | B-Tree Partial | WHERE status='GAGAL' (97.96% hemat) |
| ev_terjadi_pada_idx | 43 MB | B-Tree | (terjadi_pada DESC) |
| ev_cover_idx | 77 MB | B-Tree Covering | (customer_id) INCLUDE (terjadi_pada, jumlah) |
| ev_tiga_kolom_idx | 77 MB | B-Tree | (customer_id, terjadi_pada, jumlah) |
| ev_email_lower_idx | 86 MB | B-Tree Expression | lower(email) |
| ev_payload_gin_idx | 7 MB | GIN | payload jsonb_path_ops (1.5% dari heap) |
| ev_tags_gin_idx | 4664 kB | GIN | tags array |
| ev_terjadi_pada_brin_idx | 32 kB | BRIN | terjadi_pada (1400x lebih kecil dari B-Tree) |
| ev_status_idx | 13 MB | B-Tree | status |

## Statistik Penggunaan Index (idx_scan)

| Index | idx_scan | Keputusan |
|-------|----------|-----------|
| ev_payload_gin_idx | 3 | Dipertahankan |
| ev_cover_idx | 2 | Dipertahankan |
| ev_gagal_idx | 2 | Dipertahankan |
| ev_status_idx | 2 | Dipertahankan |
| event_log_pkey | 2 | Wajib (PRIMARY KEY) |
| ev_email_lower_idx | 1 | Dipertahankan |
| ev_terjadi_pada_idx | 1 | Dipertahankan |
| ev_tiga_kolom_idx | 1 | Dipertahankan |
| ev_tags_gin_idx | 1 | Dipertahankan |
| ev_benar_idx | 0 | Kandidat hapus (duplikat fungsi) |
| ev_salah_idx | 0 | Kandidat hapus (tidak terpakai) |
| ev_terjadi_pada_brin_idx | 0 | Kandidat hapus (B-Tree lebih cepat) |

## Perbandingan INSERT Performance

| Kondisi | Waktu | Ukuran Total | Selisih |
|---------|-------|--------------|---------|
| Tanpa index | 2.1 detik | 13 MB | Baseline |
| Dengan 5 index | 17.1 detik | 59 MB | 715% lebih lambat, 4.5x lebih besar |

## Correlation Statistics

| Kolom | Correlation | Keterangan |
|-------|-------------|------------|
| terjadi_pada | 1.0 | Sangat terurut (ideal untuk BRIN) |
| wilayah | 0.196 | Tidak terurut |
| kota | 0.021 | Tidak terurut |

## Catatan Penting
1. **Urutan kolom index sangat penting**: Q9 (0.131 ms) vs Q8 (49 ms) = 376x perbedaan
2. **Partial index sangat efisien**: 97.96% penghematan ruang untuk data yang selektif
3. **GIN tidak selalu lebih cepat**: Untuk selektivitas rendah (25%), Seq Scan lebih cepat
4. **BRIN cocok untuk time-series**: 1400x lebih kecil dari B-Tree untuk data terurut
5. **VACUUM penting untuk Index-Only Scan**: Heap Fetches = 0 setelah VACUUM
6. **Index memperlambat INSERT**: 715% lebih lambat dengan 5 index