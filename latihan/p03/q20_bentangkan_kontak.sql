-- Diminta: bentangkan array kontak menjadi satu baris per kontak, notifikasi dengan array
-- kosong tetap muncul.
-- Dipilih: LEFT JOIN LATERAL dengan jsonb_array_elements dan ON true.
-- Alternatif: JSON_TABLE; tidak dipilih karena memerlukan sintaks kompleks.

SELECT
    n.payload->>'trx' AS nomor_transaksi,
    k.value->>'jenis' AS jenis,
    k.value->>'nomor' AS nomor
FROM notifikasi n
LEFT JOIN LATERAL jsonb_array_elements(n.payload->'kontak') AS k(value) ON true
ORDER BY nomor_transaksi, jenis;