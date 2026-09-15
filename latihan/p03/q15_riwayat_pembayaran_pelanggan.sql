-- Diminta: untuk setiap pelanggan, urutan pembayaran, jarak hari dari pembayaran sebelumnya,
-- dan total belanja sebagai kolom pendamping.
-- Dipilih: PARTITION BY customer_id dengan ROW_NUMBER, LAG, dan SUM dengan frame partisi penuh.
-- Alternatif: subquery berkorelasi; tidak dipilih karena window lebih efisien.

SELECT
    customer_id,
    payment_id,
    payment_date::date AS tanggal,
    amount,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY payment_date) AS urutan,
    payment_date::date - LAG(payment_date::date, 1) OVER (PARTITION BY customer_id ORDER BY payment_date) AS jarak_hari,
    SUM(amount) OVER (PARTITION BY customer_id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS total_belanja
FROM payment
ORDER BY customer_id, payment_date;