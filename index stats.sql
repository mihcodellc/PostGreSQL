SELECT
    s.relname AS table_name,
    i.relname AS index_name,
    idx_scan AS index_scans,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched
FROM
    pg_stat_user_indexes si
JOIN
    pg_class i ON si.indexrelid = i.oid
JOIN
    pg_class s ON si.relid = s.oid
where i.relname in ('ix1','ix2' )
ORDER BY
    idx_scan DESC limit 10;
