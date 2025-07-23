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
where i.relname in ('ix_1','ix_2' )
ORDER BY
    idx_scan DESC limit 10;


 SELECT relname,
        CASE idx_scan
          WHEN 0 THEN
			'Insufficient data'
          ELSE
		    (100 * idx_scan / (seq_scan + idx_scan ) ) ::text
    	END percent_of_times_index_used,
    	n_live_tup rows_in_table
   FROM pg_stat_user_tables
   where relname in ('medrx_config' )
  ORDER BY n_live_tup DESC;

--for all indexes, not just user-defined
SELECT * FROM pg_stat_all_indexes WHERE schemaname = 'public';




--recap
SELECT
    t.relname AS table_name,
    i.relname AS index_name,
    CASE
        WHEN st.idx_scan = 0 THEN 'Insufficient data'
        ELSE ROUND(100.0 * st.idx_scan / (stt.seq_scan + st.idx_scan), 2)::text
    END AS percent_index_usage,
    st.idx_scan,
    stt.seq_scan,
    stt.n_live_tup AS rows_in_table
FROM
    pg_stat_user_indexes st
JOIN
    pg_class i ON i.oid = st.indexrelid
JOIN
    pg_stat_user_tables stt ON st.relid = stt.relid
JOIN
    pg_class t ON t.oid = st.relid
WHERE
    t.relname = 'medrx_config'
ORDER BY
    st.idx_scan DESC;
