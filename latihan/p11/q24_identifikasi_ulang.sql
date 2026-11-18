-- Diminta: mengukur penurunan keunikan kuasi-pengenal setelah generalisasi tanggal lahir menjadi tahun, menghitung penurunannya, dan menunjukkan pasangan query agregat yang bisa mengungkap satu orang.
-- Dipilih: menghitung kombinasi unik (kota, lahir) dibanding (kota, tahun lahir), lalu serangan differencing.
-- Alternatif: menghapus kolom tanggal lahir sepenuhnya; tidak dipilih karena analis masih membutuhkan distribusi tahun lahir.
-- Dijalankan sebagai: postgres (sebagai penyerang yang memegang salinan data mentah, mis. dari cadangan yang bocor).

-- 1) Penurunan keunikan
WITH asal AS (
  SELECT count(*) AS unik_asal FROM (
    SELECT kota, lahir FROM lab11.pelanggan GROUP BY kota, lahir HAVING count(*) = 1
  ) s
),
gen AS (
  SELECT count(*) AS unik_tahun FROM (
    SELECT kota, thn FROM (SELECT kota, extract(year FROM lahir)::int AS thn FROM lab11.pelanggan) x
    GROUP BY kota, thn HAVING count(*) = 1
  ) s
)
SELECT unik_asal, unik_tahun,
       round((unik_asal - unik_tahun)::numeric / greatest(unik_asal, 1) * 100, 2) AS persen_penurunan
  FROM asal, gen;

-- 2) Serangan differencing: selisih dua agregat = saldo satu orang.
-- Ganti 1 dengan id penyewa Medan mana pun: SELECT id FROM lab11.pelanggan WHERE kota = 'Medan' ORDER BY id LIMIT 1;
SELECT (SELECT sum(saldo) FROM lab11.pelanggan WHERE kota = 'Medan')
     - (SELECT sum(saldo) FROM lab11.pelanggan WHERE kota = 'Medan' AND id <> 1) AS saldo_satu_orang;
-- Verifikasi: SELECT saldo FROM lab11.pelanggan WHERE id = 1;  (harus sama)
-- Catatan: pada view v_pelanggan_samar saldo dibulatkan ke 100000 sehingga selisih tidak tepat; ini meredam, bukan menghapus, risiko.
