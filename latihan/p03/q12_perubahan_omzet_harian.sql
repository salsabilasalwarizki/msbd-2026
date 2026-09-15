-- Diminta: omzet harian, omzet hari sebelumnya, selisih, dan persentase perubahan.
-- Dipilih: LAG dengan default 0 dan NULLIF untuk hindari pembagian dengan nol.
-- Alternatif: self-join; tidak dipilih karena LAG lebih ringkas dan efisien.

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
    LAG(omzet, 1, 0) OVER (ORDER BY tanggal) AS omzet_hari_lalu,
    omzet - LAG(omzet, 1, 0) OVER (ORDER BY tanggal) AS selisih,
    ROUND(
        ((omzet - LAG(omzet, 1, 0) OVER (ORDER BY tanggal)) /
        NULLIF(LAG(omzet, 1, 0) OVER (ORDER BY tanggal), 0) * 100)::numeric,
        2
    ) AS persen_perubahan
FROM omzet_harian
ORDER BY tanggal;