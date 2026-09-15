-- Diminta: jalankan ulang Q13 tanpa klausa frame (RANGE default), bandingkan dengan Q13.
-- Dipilih: EXCEPT untuk menemukan tanggal yang berbeda.
-- Alternatif: FULL JOIN; tidak dipilih karena EXCEPT lebih sederhana untuk perbedaan.

WITH omzet_harian AS (
    SELECT
        payment_date::date AS tanggal,
        SUM(amount) AS omzet
    FROM payment
    GROUP BY payment_date::date
),
versi_rows AS (
    SELECT
        tanggal,
        SUM(omzet) OVER (ORDER BY tanggal ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS kumulatif
    FROM omzet_harian
),
versi_range AS (
    SELECT
        tanggal,
        SUM(omzet) OVER (ORDER BY tanggal) AS kumulatif
    FROM omzet_harian
)
SELECT tanggal, kumulatif AS kumulatif_rows
FROM versi_rows
EXCEPT
SELECT tanggal, kumulatif
FROM versi_range;