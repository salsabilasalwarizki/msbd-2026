-- Diminta: menghitung fraksi tiap status dan mencari titik transisi index scan ke seq scan.
-- Dipilih: GROUP BY status dengan count.
-- Alternatif: hanya satu status; tidak dipilih karena diminta semua.

-- Fraksi tiap status
SELECT
  status,
  count(*) AS jumlah,
  round(count(*)::numeric / (SELECT count(*) FROM lab6.event_log) * 100, 2) AS persen
FROM lab6.event_log
GROUP BY status
ORDER BY jumlah DESC;

-- Titik transisi biasanya sekitar 5-15% dari total baris
-- Di bawah itu: index scan lebih cepat
-- Di atas itu: seq scan lebih cepat (karena overhead random access)