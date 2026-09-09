-- Diminta: seluruh pegawai beserta level kedalaman dan jalur jabatan dari puncak.
-- Dipilih: recursive CTE dengan anchor atasan_id IS NULL dan array untuk jalur.
-- Alternatif: self-join bertingkat; tidak dipilih karena kedalaman tidak tetap.

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
SELECT pegawai_id, nama, level, array_to_string(jalur, ' > ') AS jalur_jabatan
FROM hierarki
ORDER BY jalur;