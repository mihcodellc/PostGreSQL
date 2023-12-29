-- --pg_lsclusters on ubuntu as postgres user
-- 9.3 
-- main    
-- 5444  
-- postgres 
-- data directory: /var/lib/postgresql/9.3/main 
-- log file: pg_log/postgresql-%Y-%m-%d_%H%M%S.csv

--- /var/lib/postgresql/scripts/job_pgbadger.sh

--find the latest log file in log folder and pass it to pgbadger, it will generate in the current folder
-- man pgbadger: https://github.com/darold/pgbadger
-- pgbadger -f stderr /var/lib/postgresql/9.3/main/pg_log/postgresql-2023-10-20_000000.log -o /tmp/reports
-- pgbadger -f stderr /var/lib/postgresql/9.3/main/pg_log/postgresql-2023-10-*.log -o /tmp/reports
-- -b begin date and -e end date
-- pgbadger -b "2023-10-16 00:00:11" -e "2023-10-22 23:59:59"  -f stderr /var/lib/postgresql/9.3/main/pg_log/postgresql-2023-10*.csv
-- instead of stderr
--  pgbadger --prefix '%t [%p]: user=%u,db=%d,client=%h'   /var/lib/postgresql/9.3/main/pg_log/postgresql-2023-10-23_*.csv


--read log
cd /var/lib/postgresql/9.3/main/pg_log
grep -i  'error\|fatal\|warn' postgresql-2023-11-03_111725.csv | sort -k 1 | tail -n 1

-- Connection info 
SELECT usename, count(*) 
FROM pg_stat_activity
  GROUP by usename;

-- Long Running Queries
 SELECT pid,usename,
        now() - pg_stat_activity.query_start AS duration,
        query AS query
   FROM pg_stat_activity
  WHERE pg_stat_activity.query <> ''::text
    AND now() - pg_stat_activity.query_start > interval '5 minutes'
    AND usename = 'dprober'
  ORDER BY now() - pg_stat_activity.query_start DESC;

SELECT usename, count(*)
   FROM pg_stat_activity
  WHERE pg_stat_activity.query <> ''::text
    AND now() - pg_stat_activity.query_start > interval '5 minutes'
 GROUP by usename
  
-- blocking queries
SELECT	bl.pid AS blocked_pid,
        a.query AS blocking_statement,
        now ( ) - ka.query_start AS blocking_duration,
        kl.pid AS blocking_pid,
        a.query AS blocked_statement,
        now ( ) - a.query_start AS blocked_duration
   FROM pg_catalog.pg_locks bl
   JOIN pg_catalog.pg_stat_activity a ON bl.pid = a.pid
   JOIN pg_catalog.pg_locks kl
   JOIN pg_catalog.pg_stat_activity ka
        ON kl.pid = ka.pid
        ON bl.transactionid = kl.transactionid
    AND bl.pid != kl.pid
  WHERE NOT bl.granted;


-- indexes
 SELECT pg_size_pretty(sum(relpages::bigint)) AS size
   FROM pg_class
  WHERE reltype=0;


SELECT *
FROM pg_stat_user_indexes


SELECT relname AS name,
        pg_size_pretty (sum (relpages::BIGINT * 8192)::BIGINT) AS SIZE
   FROM pg_class
  WHERE reltype = 0 -- zero for indexes, sequences, and toast tables, which have no pg_type
            --can also use pg_class.relkind defined in bello_postgres.sql
  GROUP BY relname
  ORDER BY sum(relpages) DESC;


--- vacuum stats
WITH table_opts AS
  (SELECT pg_class.oid,
          relname,
          nspname,
          array_to_string(reloptions, '') AS relopts
    FROM pg_class
   INNER JOIN pg_namespace ns ON relnamespace = ns.oid),
     vacuum_settings AS
   (SELECT oid,
           relname,
           nspname,
           CASE
               WHEN relopts LIKE '%autovacuum_vacuum_threshold%' THEN regexp_replace(relopts, '.*autovacuum_vacuum_threshold=([0-9.]+).*', E'\\\\\\1')::integer
               ELSE current_setting('autovacuum_vacuum_threshold')::integer
           END AS autovacuum_vacuum_threshold,
           CASE
               WHEN relopts LIKE '%autovacuum_vacuum_scale_factor%' THEN regexp_replace(relopts, '.*autovacuum_vacuum_scale_factor=([0-9.]+).*', E'\\\\\\1')::real
               ELSE current_setting('autovacuum_vacuum_scale_factor')::real
           END AS autovacuum_vacuum_scale_factor
    FROM table_opts)
  SELECT vacuum_settings.nspname AS SCHEMA,
         vacuum_settings.relname AS TABLE,
         to_char(psut.last_vacuum, 'YYYY-MM-DD HH24:MI') AS last_vacuum,
         to_char(psut.last_autovacuum, 'YYYY-MM-DD HH24:MI') AS last_autovacuum,
         to_char(pg_class.reltuples, '9G999G999G999') AS rowcount,
         to_char(psut.n_dead_tup, '9G999G999G999') AS dead_rowcount,
         to_char(autovacuum_vacuum_threshold + (autovacuum_vacuum_scale_factor::numeric * pg_class.reltuples), '9G999G999G999') AS autovacuum_threshold,
         CASE
             WHEN autovacuum_vacuum_threshold + (autovacuum_vacuum_scale_factor::numeric * pg_class.reltuples) < psut.n_dead_tup THEN 'yes'
         END AS expect_autovacuum
  FROM pg_stat_user_tables psut
  INNER JOIN pg_class ON psut.relid = pg_class.oid
  INNER JOIN vacuum_settings ON pg_class.oid = vacuum_settings.oid
  ORDER BY 1,
           2;

