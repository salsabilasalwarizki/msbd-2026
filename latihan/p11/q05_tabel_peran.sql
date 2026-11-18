-- Diminta: memetakan tujuh peran pada lab11 beserta hak akses dan status login-nya.
-- Dipilih: query katalog pg_roles dan pg_auth_members untuk memverifikasi atribut dan keanggotaan peran.
-- Alternatif: mencatat manual tanpa verifikasi katalog; tidak dipilih karena berisiko keliru.
-- Catatan: daftar nama di bawah mengasumsikan tujuh peran = postgres + enam peran lab. Sesuaikan dengan skrip setup bila berbeda.

SELECT rolname AS nama_peran,
       rolcanlogin AS bisa_login,
       rolbypassrls AS bypass_rls,
       rolsuper AS superuser
FROM pg_roles
WHERE rolname IN ('postgres', 'skema_owner', 'app_read', 'app_write', 'app_laporan', 'app_portal', 'app_analitik')
ORDER BY rolcanlogin, rolname;

SELECT anggota.rolname AS anggota, peran.rolname AS memiliki_peran
FROM pg_auth_members m
JOIN pg_roles anggota ON anggota.oid = m.member
JOIN pg_roles peran   ON peran.oid   = m.roleid
WHERE anggota.rolname LIKE 'app_%'
ORDER BY 1, 2;

-- Satu kalimat penjelasan (tulis di laporan.md):
-- Aplikasi tidak pernah login sebagai pemilik (skema_owner) karena pemilik memiliki hak bawaan destruktif (DROP, ALTER)
-- yang tidak bisa dicabut dengan REVOKE, sehingga satu bug aplikasi dapat menghancurkan seluruh skema.
