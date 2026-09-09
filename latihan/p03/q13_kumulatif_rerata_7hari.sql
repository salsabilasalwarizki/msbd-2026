-- Diminta: omzet harian, total kumulatif, dan rata-rata bergerak 7 hari.
-- Dipilih: dua window function dengan frame ROWS yang berbeda.
-- Alternatif: subquery berkorelasi; tidak dipilih karena window lebih efisien.

WITH omzet_harian AS (
    SELECT
        payment_date::date AS tanggal,
        SUM(amount) AS omzet
    FROM payment
    GROUP BY payment_date::date
)
SELECT
    tanggal,
    omzet,
    SUM(omzet) OVER (ORDER BY tanggal ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS kumulatif,
    ROUND(AVG(omzet) OVER (ORDER BY tanggal ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)::numeric, 2) AS rerata_7hari
FROM omzet_harian
ORDER BY tanggal;