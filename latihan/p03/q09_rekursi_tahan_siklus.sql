-- Diminta: buat siklus, amati Q7, perbaiki agar tahan siklus, pulihkan data.
-- Dipilih: klausa CYCLE karena lebih ringkas dan otomatis mendeteksi siklus.
-- Alternatif: pelacakan array dengan NOT (... = ANY(...)); tidak dipilih karena CYCLE lebih bersih.

-- Buat siklus
UPDATE pegawai SET atasan_id = 6 WHERE pegawai_id = 1;

-- Query tahan siklus dengan CYCLE
WITH RECURSIVE hierarki AS (
    SELECT
        pegawai_id,
        nama,
        atasan_id,
        1 AS level,
        ARRAY[nama] AS jalur
    FROM pegawai
    WHERE atasan_id IS NULL

    UNION ALL

    SELECT
        p.pegawai_id,
        p.nama,
        p.atasan_id,
        h.level + 1,
        h.jalur || p.nama
    FROM pegawai p
    JOIN hierarki h ON p.atasan_id = h.pegawai_id
)
CYCLE pegawai_id SET is_siklus USING jalur_siklus
SELECT pegawai_id, nama, level, array_to_string(jalur, ' > ') AS jalur_jabatan
FROM hierarki
WHERE NOT is_siklus
ORDER BY jalur;

-- Pulihkan data
UPDATE pegawai SET atasan_id = NULL WHERE pegawai_id = 1;