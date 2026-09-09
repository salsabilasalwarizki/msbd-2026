-- Diminta: semua bawahan langsung dan tidak langsung dari Bima, beserta jaraknya.
-- Dipilih: recursive CTE dengan anchor disaring pada nama 'Bima'.
-- Alternatif: subquery bertingkat; tidak dipilih karena kedalaman hierarki tidak tetap.

WITH RECURSIVE bawahan AS (
    SELECT
        pegawai_id,
        nama,
        atasan_id,
        0 AS jarak
    FROM pegawai
    WHERE nama = 'Bima'

    UNION ALL

    SELECT
        p.pegawai_id,
        p.nama,
        p.atasan_id,
        b.jarak + 1
    FROM pegawai p
    JOIN bawahan b ON p.atasan_id = b.pegawai_id
)
SELECT pegawai_id, nama, jarak
FROM bawahan
WHERE nama <> 'Bima'
ORDER BY jarak, nama;