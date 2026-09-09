-- Diminta: laporan pendapatan bulanan per kategori dengan peringkat, pertumbuhan,
-- kumulatif, dan porsi persen.
-- Dipilih: CTE bulanan dengan beberapa window function yang dipartisi berbeda.
-- Alternatif: subquery bertingkat; tidak dipilih karena window lebih efisien.

WITH bulanan AS (
    SELECT
        date_trunc('month', p.payment_date)::date AS bulan,
        c.name AS kategori,
        SUM(p.amount) AS pendapatan
    FROM payment p
    JOIN rental r ON r.rental_id = p.rental_id
    JOIN inventory i ON i.inventory_id = r.inventory_id
    JOIN film_category fc ON fc.film_id = i.film_id
    JOIN category c ON c.category_id = fc.category_id
    GROUP BY 1, 2
)
SELECT
    bulan,
    kategori,
    ROUND(pendapatan::numeric, 2) AS pendapatan,
    RANK() OVER (
        PARTITION BY bulan
        ORDER BY pendapatan DESC
    ) AS peringkat,
    ROUND(LAG(pendapatan) OVER (
        PARTITION BY kategori
        ORDER BY bulan
    )::numeric, 2) AS bulan_lalu,
    ROUND(
        ((pendapatan - LAG(pendapatan) OVER (
            PARTITION BY kategori
            ORDER BY bulan
        )) / NULLIF(LAG(pendapatan) OVER (
            PARTITION BY kategori
            ORDER BY bulan
        ), 0) * 100)::numeric,
        2
    ) AS pertumbuhan_persen,
    ROUND(SUM(pendapatan) OVER (
        PARTITION BY kategori
        ORDER BY bulan
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )::numeric, 2) AS pendapatan_kumulatif,
    ROUND(
        (pendapatan / SUM(pendapatan) OVER (
            PARTITION BY bulan
        ) * 100)::numeric,
        2
    ) AS porsi_persen
FROM bulanan
ORDER BY bulan, peringkat
LIMIT 10; 
-- Limit 10 Untuk menghasilkan 10 baris pertama