-- https://www.red-gate.com/simple-talk/blogs/how-can-sql-server-developers-get-started-with-postgre-sql/#:~:text=HOW%20CAN%20SQL%20SERVER%20DEVELOPERS%20GET%20STARTED%20WITH,JOIN%20m%20...%20%2014%20more%20rows%20
-- https://www.postgresql.org/docs/9.3/sql-syntax-lexical.html
-- https://www.postgresql.org/docs/9.3/sql-syntax.html
-- https://www.postgresql.org/docs/9.3/sql.html
-- https://www.postgresql.org/docs/9.3/plpgsql.html
--tsql
set showplan_xml on
go
set noexec on
go 
select * from TABLE

--pgsql
EXPLAIN analyze select * from TABLE

--data type 
datetime/datetime2 (tsq) => timestamp(psql) with time zone => datetimeoffset (tsql) 
varchar(n) n ie n bytes length (tsql) <> n ie n characters length
no confusion with timestamp  = rowversion in TSQL

-- add a new column with default to a table works differently in pg 9.3 versus tsql 2017.
pg will update the previous value by default. If not wanted, please find other solution

alter table mytable add col1 int not null constraint df_col1 default 0 --update the previous column
----select top 1 col1,* from mytable 
--alter table payments drop constraint df_col1
--alter table payments drop column col1	


--***reindex
-- Whenever CREATE INDEX or REINDEX is running, the pg_stat_progress_create_index view will contain one row for each backend 
	--that is currently creating indexes. 
tsql : DBCC DBREINDEX ('schema.my_table', my_index, 80); --always offline no online
       DBCC DBREINDEX ('schema.my_table', ' ', 80); -- all indexes	
	CREATE INDEX index1 ON table1 (Col1 DESC)   WITH (DROP_EXISTING = ON, fillfactor = 80, ONLINE=ON) WHERE <filter_predicate> ];
	ALTER INDEX index1 ON table1 REBUILD; -- rebuild or reorganize	ALTER INDEX ALL ON table1 REBUILD;
	ALTER INDEX test_idx on test_table REBUILD WITH (ONLINE = ON, MAXDOP = 1, RESUMABLE = ON) ; --resumable rebuild
		ALTER INDEX test_idx on test_table PAUSE ;
		ALTER INDEX test_idx on test_table RESUME WITH (MAXDOP = 4) ;
		ALTER INDEX test_idx on test_table ABORT ;
	--ALTER INDEX test_idx on test_table RESUME WITH (MAXDOP = 2, MAX_DURATION = 240 MINUTES,  WAIT_AT_LOW_PRIORITY (MAX_DURATION = 10, ABORT_AFTER_WAIT = BLOCKERS)) ;
	drop index if exists test_idx on test_table with(ONLINE=ON)
		
psql : REINDEX INDEX my_index;
REINDEX TABLE CONCURRENTLY my_table; --CONCURRENTLY online of tsql from v12 of PG

SET enable_wal_logging = true; -- force PostgreSQL to log it for replica

CREATE INDEX CONCURRENTLY index1 ON my_table (col1) include (col1) WITH (fillfactor = 80) [ WHERE predicate ] ; ---include not eval
DROP INDEX index1;
DROP INDEX CONCURRENTLY if exists index1;


-- index build progress on v 9.3 better in later version
SELECT pid, query, state, now() - pg_stat_activity.query_start AS duration, application_name, usename, datname
FROM pg_stat_activity
WHERE query LIKE 'CREATE INDEX%' AND state = 'active';


--closest tsql
select datediff(mm,'20150101', '20210401')
select datediff(dd,'20150101', '20210401')	
select datediff(hh,'20150101', '20210401')
select datediff(MINUTE,'20150101', '20210401')

select datepart(yy,getdate())
select datepart(SECOND,getdate())

--pgsql date diff with extract or +/-
SET intervalstyle = 'postgres';
SELECT
	INTERVAL '6 years 5 months 4 days 3 hours 2 minutes 1 second';

SELECT EXTRACT (MINUTE FROM INTERVAL '5 hours 21 minutes');
select col1, Datecol2 from mytable 
where EXTRACT(MONTH FROM Datecol2  ) = 9 and EXTRACT(year FROM Datecol2 ) = 2023 order by col1 desc limit 1
select age(now(),'2022-04-27 12:11:50.029451-05')
SELECT current_date, AGE (timestamp '2001-10-10');-- age and current date
SELECT AGE (timestamp '2001-01-01', timestamp '2020-10-20'); -- "-19 years -9 mons -19 days"

select '20230326 07:30:00.000'::timestamp + INTERVAL '90 days' ---return date & time
select '20230326 07:30:00.000'::date + 90 -- return date
select to_date('31/12/2020','dd/mm/yyyy') ; -- know your format


-- like 
a.adsrc like '%merchantbatch_id_seq%'; --psql 
	vs 
a.adsrc like '*merchantbatch_id_seq*'; --tsql
a.adsrc ~ 'merchantbatch_id_seq'; -- psql
a.adsrc ilike 'merchantbatch_id_seq'; --psql case-insensitive


--array comparison -- https://www.postgresql.org/docs/9.3/functions-array.html
SELECT relname, relacl
FROM pg_class
WHERE relacl IS NOT NULL -- To filter only non-null ACLs
   AND ARRAY['postgres=arwdDxt/postgres']::aclitem[] <@ relacl;
  -- AND relacl::text ~ 'mbello';


--***begin tran and roll it back
--psql
begin; --block limit in tsql
	<statement in psql>
rollback;--commit

do $$ 
declare v_count int :=0;
begin
   --statement
end  
$$; --; can be just after end
DO $$ -- with paramter in and out
DECLARE
    sql_query TEXT;
    result INT[]:='{2023}';
    outin INT;
BEGIN
    sql_query := 'SELECT count(*) FROM mytable WHERE id  = ANY($1) order by 1';
    EXECUTE sql_query USING result INTO outin;
    RAISE NOTICE 'Result: %', outin;
END $$;

--tsql
begin tran
	<statement in tsql>
rollback tran--commit tran

--declare @count int = 0;	HIS PLACE doesn't matter
begin 
   declare @count int = 0;
   --statement
end


--***insert, UPDATE, delete: obtain data from modified rows while they are being manipulated
--psql	
--INSERT, UPDATE, and DELETE commands all have an optional RETURNING clause 
--In an INSERT, the data available to RETURNING is the row as it was inserted.	
--IN an UPDATE, the data available to RETURNING is the new content of the modified row
--In a DELETE, the data available to RETURNING is the content of the deleted row
insert into j_posts_tags values(1,2) returning *;
delete from t_posts p where exists (select 1 from categories c where c.pk=p.category and c.title='apple') 
	returning pk,title,category;
with cte as (
UPDATE products SET price = price * 1.10
  WHERE price <= 99.99
  RETURNING name, price AS new_price;
) select * from cte
--tsql
UPDATE products SET price = price * 1.10
	OUTPUT deleted.price as OldPrice, inserted.price as NewPrice INTO #temp
  WHERE price <= 99.99

---***concatenate string and assign 
select 'text 1' || ' text 2' into v_t1t2--psql
select @t1t2 = 'text 1' + ' text 2' --tsql

--IIF in TSQL not in psql, use Case instead



--create db forumdb2 from existing forumdb
create database forumdb2 template forumdb;


--kill session
--PG
select pid, query from pg_stat_activity where usename='mbello';  -- get PID -- pid = 3343, 12582
select pg_cancel_backend(3343); --Cancels the current query of the session
-- pg_terminate_backend: Does not rollback. 
-- if timeout not specified, returns true whether the process actually terminates or not. 
-- If the process is terminated, the function returns true.
select pg_terminate_backend(3343, <timeout bigint DEFAULT 0>); 
--rerun to confirm it s gone
select pid, query from pg_stat_activity where usename='mbello';



--NULL value
select * from categories order by description NULLS last; -- by default PG
--TSQL NULL first


--tsql Merge
--plsql UPSERT
INSERT INTO table_name(column_list) VALUES(value_list) ON CONFLICT target action;
insert into j_posts_tags values(1,2) ON CONFLICT (tag_pk,post_pk) DO UPDATE set tag_pk=excluded.tag_pk+1;
-- It gets replaced with this statement
UPDATE set tag_pk=tag_pk+1 where tag_pk=1 and post_pk=2


--export to csv
tsql: bcp or sqlcmd or openrowset
plsql: COPY (q<uery>) TO 'filename.csv' with  (Delimiter '|' , FORMAT CSV, HEADER TRUE,  ESCAPE E'\\');

-- import : where /tmp/reports/ is 777
COPY public.mytable FROM '/tmp/reports/Sample.csv' WITH (FORMAT csv);
-- https://www.postgresql.org/docs/current/sql-copy.html
--import data
COPY public.forpg FROM '/tmp/reports/Sample.csv' WITH (FORMAT csv);
COPY public.forpg FROM '/tmp/reports/valQuery.csv' WITH (FORMAT csv, FORCE_NOT_NULL (documenttype)); -- null are not matched
COPY public.forpg FROM '/tmp/reports/valQuery.csv' WITH (FORMAT csv);
--export data
COPY public.forpg( id, lockboxnumber ) TO '/tmp/reports/valColums.csv' WITH (FORMAT csv);
COPY (select * from public.forpg limit 1000) TO '/tmp/reports/valQuery.csv' WITH (FORMAT csv);
COPY (select id, documenttype from public.forpg where documenttype is NULL limit 1000) TO '/tmp/reports/valQuery.csv' WITH (FORMAT csv);


-- run a .sql file: use a login  with enough priv to execute the query. 
--	eg postgres account: 1. create the bash file, make executable with chmod then use crontab to run it under the same login
-- load/run the script 	
 psql -d new_db -f /tmp/payer_solution.sql
	or
sqlfile=/tmp/payer_solution.sql
logfile=/tmp/myapp.log	
psql prod1  -f $sqlfile     >> $logfile
	
psql prod1 -f $sqlfile  -o $outfile


-- generate numeric pg/sql VS tsql 2022
select generate_series(1,5); -- 1 to 5 numeric
SELECT DATEADD(minute, s.value, 'Dec 10, 2022 1:00 PM') AS [Interval]
FROM GENERATE_SERIES(0, 59, 1) AS s;
-- 

-- The PostgreSQL NTILE function groups the rows sorted in the partition
-- The parameter passed to the NTILE function determines how many records we want the bucket to be composed of
SELECT NTILE(4) OVER(ORDER BY SalesYTD DESC) AS Quartile, CONVERT(NVARCHAR(20),s.SalesYTD,1) AS SalesYTD  
FROM Sales.SalesPerson AS s
SELECT x,ntile(2) over w from (select generate_series(1,6) as x) V WINDOW w as (order by x) ;


--CUME_DIST Returns the cumulative distribution, that is (number of partition rows preceding or peers with current row) / (total partition rows). 
-- The value thus ranges from 1/N to 1.
select x,cume_dist() over w from (select generate_series(1,5) as x) V WINDOW w as (order by x) ;
 x | cume_dist 
---+-----------
 1 | 0.2
 2 | 0.4
 3 | 0.6
 4 | 0.8
 5 | 1


-- frame clause
	 --ROWS BETWEEN start_point and end_point
SELECT x, SUM(x) OVER w
 FROM (select generate_series(1,5) as x) V
 WINDOW w AS (ORDER BY x ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW);
 x | sum 
---+-----
 1 | 1
 2 | 3
 3 | 6
 4 | 10
 5 | 15
	 --RANGE BETWEEN start_point and end_point
SELECT x, SUM(x) OVER w
 FROM (select generate_series(1,5) as x) V
 WINDOW w AS (ORDER BY x RANGE BETWEEN 1 PRECEDING AND CURRENT ROW);
 x | sum 
---+-----
 1 | 1
 2 | 3
 3 | 5
 4 | 7
 5 | 9
