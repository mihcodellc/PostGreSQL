 1986 Postgres or Post-Ingres by Michael Stonebraker to Postgre95 to PostgreSQL
 4 billion individual databases
 1 billion tables, each containing 32 TB of data
 1,600 columns, each 1 GB in size, with an unlimited number of multi-column (up to 32 columns) indexes.
 with other embedded languages, such as Perl, Python, Java, and even Bash!
 support and upgrades for 5 years after a new release is issued;
 
  A PostgreSQL instance is called a cluster because a single instance can serve and handle multiple databases. 
  Every database is an ISOLATED space where users and applications can store data
 
  PostgreSQL stores all of its content
  (user data and internal status) in a single filesystem directory known as PGDATA
  
  PGDATA directory is made by at least the 
	- write-ahead (intent) logs (WALs) and the 
	- data storage. 
	Without either of those two parts, the cluster is unable to guarantee data consistency and, in some critical circumstances, even start.
  
  PostgreSQL relies on the underlying filesystem to implement persistence, and 
  therefore tuning the filesystem is an important task in order to make PostgreSQL perform well
  
PostgreSQL catalog is much more accurate and 
	PostgreSQL-specific that the general information schema compared to information schema
	
postmaster: When the cluster is started, a single process called the postmaster is launched	
postmaster is just the root of all PostgreSQL processes, with the main aim of keeping all the other processes under control
backend: every time a new connection against the cluster is opened, the cluster reacts by launching 
	a new backend process to serve it until the connection ends
contrib package: is a set of well-known extensions and utilities that can enhance your PostgreSQL experience	
 
Installing PostgreSQL via pgenv for mutilversion environement on same machine 
 
Amazon RDS, 
Amazon RedShift,
Aurora PostgreSQL 
	are PostgreSQL variants
	
Amazon Babelfish on Aurora PostgreSQL , sql server run on Postgres

heap-based non clustering,just to reorder once the ROWS and gone
	rows always add to the end. old get vaccumed
no queries hints
maintenance with VACUUM
Statistics updated with ANALYZE	

non serverless postgres should be tuned fir your workload

work_mem for each operator not for the whole query_start
config to review frequently postgresql.conf
	shared _buffers (norm 25% of RAM)
	maintenance_work_mem
	max_connections

extensions added per-database but has to be add to the server first or add to model
	--select * from pg_available_extensions order by name
	--create(install) extension a_name/alter extension a_name UPDATE/drop extension a_name
	pg_stat_statements(stats of SQL statements)
	pgagent(job scheduler)
	HypoPG(Hypothetical Index)
	pgrowlocks(row-level locking information)
	fdw_*(Foreign data wrapers)
		file, postgres, TDS db (MSSQL or SyBase)
	tablefunc(Pivot & crosstab)
	ZomboDB(Elasticsearch index)
    
create database and restore a backup TO this database; empty at beginning
model db = template0 & template1
	template1 used to create new by default

pg_basebackup -- point in time recovery
pg_dump -- regular 
pg_restore

https://psql-tips.org/psql_tips_all.html
https://planet.postgresql.org/
DBeaver


***datatypes --https://www.postgresql.org/docs/current/datatype.html
address types: inet, cidr, macaddress
bit(n) and bit varying(n)
json types

lower case your statements
 or snake_case
 or quotes object/column "Table" or "Column" from MSSQL

*************QUERIES
postgres(1) ~~ mssql(2)
 
**LIMIT/OFFSET ~~ OFFSET/FETCH 
	paging through data
	
**NOW() ~~ GETDATE()
	now - interval '1 month 2 days 3 minutes'
	'2015-02-01'::timestamp
	select * from generate_series('2021-08-01','2021-08-03', INTERVAL '1 hour') 

**INNER JOIN LATERAL ~~ CROSS APPLY

**LEFT JOIN LATERAL ~~ OUTER APPLY

**code block 
	MSSQL default by TSQL
	postgres:  
DO --required
$$ --required or $aText$
declare a_name TEXT; -- ACTUAL PLACE FOR DECLARATION
begin --required 
	--statements
	SELECT name INTO a_name
	FROM pg_available_extensions -- from dual in oracle doesn't work here
	LIMIT 3 OFFSET 5;
	RAISE NOTICE '%', a_name;
end;  --required
$$ --required or $aText$


*************ADMIN - monitoring
pgBadger is a PostgreSQL performance analyzer, built for speed with fully detailed reports based on your PostgreSQL log files.
Ubuntu/debian
pg_lsclusters # show information about all PostgreSQL clusters ---affiche repertoire du log
	pgrep -a post # version looking at the postmaster process
pg_ctlcluster ie pg_ctl for ubuntu, tool that allows you to perform different actions on a cluster 
			 for different versions of postgresql
pg_lsclusters -s # Include start.conf information in status column.

sudo service postgresql start
sudo pg_ctlcluster stop -m smart # smart(wait all connections) or fast(disconnect all) or immediate (abort all processes)
sudo pg_ctlcluster 12 main status


--start db postgres by specifuing the data directory. good practive to log every command for trousbleshooting purpose
postgres -D /usr/local/pgsql/data > logfile
pg_ctl start -l logfile
SELECT  pg_current_logfile(); -- https://stackoverflow.com/questions/67924176/where-are-the-postgres-logs
SHOW logging_collector; --log started? ie ON
SHOW log_directory; -- where is log
show all;
show SERVER_VERSION;



--memory cpu, ....
htop -u mbello
htop -p 70 #-p ie pid
htop -s CPU # sort

-- activities
select pid, client_addr, datname, application_name, query 
from pg_stat_activity 
where  client_addr is not null
	and pid in (SELECT pid FROM pg_locks)
limit 5;

-- view locks
SELECT pid as serverProcessHolding, locktype,database, granted , mode --waitstart   
FROM pg_locks 
limit 5;
 

--table size and index size
select pg_size_pretty(pg_relation_size('accountnumber')) AS table_size, 
	   pg_size_pretty( pg_relation_size( 'idx_posts_date' ) ) AS index_size

select pg_size_pretty(pg_database_size('prod1'));
--db and size
select datname, datdba,pg_size_pretty(pg_database_size(datname)) db_size
from pg_database
;

-- auto-explain(an extension) triggers when a running query is slower than a specified threshold, and then dumps in the PostgreSQL logs
-- database administrator can get an insight into slow queries and their execution plan
-- config auto explain in postgresql.conf
session_preload_libraries = 'auto_explain'
auto_explain.log_min_duration = '500ms'
auto_explain.log_analyze = on -- ie  perform EXPLAIN ANALYZE
auto_explain.log_format(json) 
-- to query the LOG
sudo tail -f /postgres/12/log/postgresql.log
--log folder contains
postgresql-date_time.csv -- query are found here. use grep to search 
postgresql-date_time.log 


--describe table EXPLAIN ie no output rows
EXPLAIN ANALYZE select * from information_schema.columns
where table_name = 'accountnumber' limit 1;
	EXPLAIN = estimate plan
	EXPLAIN ANALYZE = Actual plan
	EXPLAIN (ANALYZE, BUFFERS, COSTS, FORMAT TEXT) -- TEXT, XML, JSON, or YAML
	EXPLAIN (COSTS off) -- off/on works for ANALYZE, BUFFERS, TIMING ...
	 EXPLAIN (ANALYZE, SUMMARY on) SELECT * FROM categories; -- return Planning Time/ Execution Time
		disk IO
	EXPLAIN (ANALYZE, BUFFERS, VERBOSE) 
	visual
		https://www.pgmustard.com/ 
			needs json format
			explain (analyze, format json, buffers, verbose)
		https://explain.depesz.com/
		

SELECT * FROM pg_class WHERE relname = 'claim_data' -- relation ie class or plsql "\d schema.claim_data" or "\d+ schema.claim_data"
Select table_name, columns.column_name, columns.is_nullable, columns.data_type, columns.character_maximum_length from information_schema.columns where table_name = 'claim_data';
--estimate of Size of the on-disk & Number of live rows
SELECT relpages, reltuples FROM pg_class WHERE relname = 'matable';
select count(*) from public.matable;

--search though postgre
-- You can do the same for views by changing "routines" to "views" or "tables" or "triggers"
SELECT routine_name,routine_catalog, routine_schema, routine_type,* 
FROM information_schema.routines -- 
where routine_definition like '%MYSTRING%' or  --routines(function, proc)
	  routine_name like '%MYSTRING%'
SELECT trigger_catalog, trigger_name, trigger_catalog, event_manipulation, 
event_object_catalog, event_object_schema, event_object_table,* 
FROM information_schema.triggers



-- proc definition
select pg_catalog.pg_get_functiondef('copy_remit_service_lines'::regproc::oid); 

--Functions
 pg trigger,db object, allows you TO CALL A FUNCTION(define as returns trigger) if an INSERT, UPDATE, DELETE or a TRUNCATE clause happens on a table
same function can be applied to many tables, is possible
tsql trigger define the STATEMENTS to execute to if an INSERT, UPDATE, or DELETE clause happens a table
pg trigger on statement level but also ROW LEVEL and add CONDITION other that before/after/instead of
	apply it to a ROWS
	NEW and OLD vs deleted, inserted
	UPDATE(col) Versus (TG_OP = 'DELETE')
 modify the cost of a function
 PG let you specify the language used by the function
 trigger before event(INSERT/UPDATE/DELETE) doesn''t exist in TSQL
 In PG to change the body of function, use CREATE or REPLACE
		ALTER FUNCTION refer to change its definition not the BODY
		whereas IN TSQL, Alter will change the definition and the BODY
 pg_trigger_depth > 0 VERSUS trigger_nestlevel() > 1
 constant trigger exists in pg fired after row triggers, from which they differ by adding a timing 
 
 
 CREATE TRIGGER sensor_trig 
    BEFORE INSERT ON t_sensor 
    FOR EACH ROW  
    EXECUTE PROCEDURE trig_func(); 
 
CREATE TRIGGER sensor_trig  
	ON Sales.Customer  
	FOR AFTER INSERT, UPDATE   
    AS 
    RAISERROR ('Notify Customer Relations', 16, 10); 

 --Views 
 in postgres they can be temp
 columns names can be specified in the same place as param for SP for BOTH
 CREATE MATERIALIZED VIEW(pgsql) close indexed view(tsql)
 pg supports also with check option but also more cascade, local
 
--Proc start postgres 11
 postgre can commit/rollback part of statement within an SP

-- devops.pg_stat_activity_view
-- query not like '%vacuum%'
-- now() - query_start > '2 minutes'

-- sp_whoisactive cpu

-- pg cancel
	-- not pg terminate
	
-- pg_stat_activity


--dependencies
--*****pg_class  : contains anything similar to table
--*****pg_attrdef: stores column default values. 
SELECT p.relname, a.adsrc FROM pg_class p
       JOIN pg_attrdef a ON (p.relfilenode = a.adrelid)
       WHERE a.adsrc ~ 'merchantbatch_id_seq';
--schemas and sizes
SELECT n.nspname, pg_size_pretty(sum(pg_relation_size(C.oid))) AS size
FROM pg_class C
LEFT JOIN pg_namespace N
	ON (N.oid = C.relnamespace)
WHERE nspname NOT IN ('pg_catalog', 'information_schema')
GROUP BY nspname;


PostgreSQL, users are referred to as login roles,

A login role is a role that has been assigned the CONNECT privilege.

each connection can have 
	one active transaction at a time and 
	one fully active statement at any time.
	
	SELECT current_database(), ;
	SELECT inet_server_addr(), inet_server_port();
	SELECT version();
	select current_user, session_user, current_role;
	
	
--command  --https://www.geeksforgeeks.org/postgresql-psql-commands/
--          https://www.postgresql.org/docs/current/app-psql.html
-- listen port default port is 5432
sudo netstat -tulpn | grep LISTEN
--psql -d database -U user -h host
sudo -i -u postgres # switch to user postgres to access the db server
psql -U postgres # connect to pg as pstgres role to db postgres
$ id mbello # id command in Linux is used to find out user and group names and numeric ID’s
--execute as login in tsql equivalent
set role to mbello
--terminate statement with ; or \g ie statement terminator
--once connect to db server # admin > not admin
--help
\h command Or \?
psql --host=localhost --dbname=postgres --username=postgres --to connect -W have you enter password
psql --host=localhost --dbname=postgres --username=postgres --to connect -W have you enter password
psql -U a_user -- will connect to a_user db
 -- introspection commands are used to query the db catalogs
\l+ list availale databasesi included size or select pg_database_size('forumdb');
\conninfo
\d all tables or table
\c change db
\a aligned/non aligned column output
\x expanded display on/off
\du or du+ user privilege --+will give more columns - user may have some priv hidden in "information_schema.table_privileges"
\dt - \d table description included indexes , columns definitions
\dT - user data type -- https://www.postgresql.org/docs/15/plpgsql-declarations.html
	select * from pg_attribute where attrelid =
        (select typrelid,* from pg_type where typname = 'type_name')
	Copying Types -> variable%TYPE : %TYPE provides the data type of a variable or table column
	Row Types : Such a variable can hold a whole row of a SELECT or FOR query result
		-> name table_name%ROWTYPE; : A row variable can be declared to have the same type as the rows of an existing table or view
		-> name composite_type_name; : 
	Record Types: Record variables are similar to row-type variables, but they have no predefined structure. 
		-> name RECORD;
\dt schema_name.*	
\dn or dn+ schema list -- also return priv on schema
\dv list view
-- permission and role as Access Control Lists (ACLs) with this format grantee=flags/grantor
-- https://www.postgresql.org/docs/current/ddl-priv.html
\dp or \z table privilege  -- also ALTER DEFAULT PRIVILEGES at https://www.postgresql.org/docs/current/sql-alterdefaultprivileges.html 
                           --on schema the priv should be GRANT USAGE ON SCHEMA x TO ROLE y
\q or quit or ctrl+D -- exit psql	

--LibPQ use by app to connect. a connection string in this lib is
postgresql://username@host:port/database

--allow connection to a port in postgresql.conf
listen_addresses = '*'

--allow user luca in pg_hba.conf after error:No pg_hba.conf entry
host all luca 127.0.0.1/32 trust

--execute statements' file.SQL
\i test.sql

-- roles
/* inspecting ACL Access Control Lists  with function aclexplode on an object here domain */
WITH acl AS (
             SELECT relname,relacl,reltuples,
                    (aclexplode(relacl)).grantor,
                    (aclexplode(relacl)).grantee,
                    (aclexplode(relacl)).privilege_type,
                    CASE relkind 
			    WHEN 'r' THEN 'table' 
			    WHEN 'v' THEN 'view' 
			    WHEN 'm' THEN 'materialized view' 
			    WHEN 'S' THEN 'sequence' 
			    WHEN 'f' THEN 'foreign table'
		    END as Type
            FROM pg_class )
         SELECT acl.relname, g.rolname AS grantee,
                acl.privilege_type AS permission,
                gg.rolname AS grantor, acl.relacl, acl.reltuples, acl.Type
         FROM acl
         JOIN pg_roles g ON g.oid = acl.grantee
         JOIN pg_roles gg ON gg.oid = acl.grantor
         WHERE acl.relname = 'domain';



create view role_routine_grants 
 (grantor, grantee, specific_catalog, specific_schema, specific_name, routine_catalog, 
routine_schema,routine_name, privilege_type, is_grantable)
--inspect privileges on different objects of databases
SELECT distinct privilege_type FROM information_schema.table_privileges where grantee = 'casharc_ro';
SELECT distinct privilege_type FROM information_schema.role_table_grants where table_name not like 'pg_%' and grantee = 'casharc_ro'; --included views
SELECT * FROM information_schema.role_routine_grants where grantee = 'casharc_ro';
SELECT * FROM information_schema.role_udt_grants where grantee = 'casharc_ro';
select * from information_schema.role_usage_grants where grantee = 'casharc_ro';
select * from information_schema.views where table_name not like 'pg_%'; --included system views

	alter role mbello with superuser
	alter role mbello with nosuperuser -- superuser, password, createdb, createrole, inherit, login, nologin...
	SELECT * FROM pg_authid /*pg_roles*/ WHERE rolname = 'luca'
	SELECT r.rolname, g.rolname AS group, m.admin_option AS is_admin
          FROM pg_auth_members m
               JOIN pg_roles r ON r.oid = m.member
               JOIN pg_roles g ON g.oid = m.roleid
		  WHERE  r.rolname = 'mbello'	   
          ORDER BY r.rolname;
		  
	execute as login 	  . set role to mbello
-- Drop user or role 
1. from terminal,connect
2. drop user mbello;
3. if complaining, becuase checking pg_shdepend but no info on type object
	-- REVOKE ALL PRIVILEGES ON DATABASE/ALL SCHEMAS/FUNCTIONS/TABLES/SEQUENCES FROM mbello
	-- REASSIGN OWNED BY mbello TO postgres;
	-- DROP USER mbello
	--keeps revoke or reassign accross databases, schemas, tables


Indexes
Postgres Statistics Collector(pg_stat_..) is a first class subsystem

index-only scan ~ covering index

https://www.geekytidbits.com/performance-tuning-postgres/#:~:text=Performance%20Tuning%20Queries%20in%20PostgreSQL%201%20Finding%20Slow,it%E2%80%99s%20time%20for%20the%20fun%20to%20begin.%20

https://www.postgresql.org/docs/current/performance-tips.html

-- 2 important links inside
--indexes on a table : plsql cmd > \d tablename or in pgadmin like management studio
-- SET enable_seqscan = OFF; get optimizer to prefer using indexes
-- set enable_indexscan = false;
-- set enable_bitmapscan = false; ie mean bitmap heap scan = seq i/o with index selectivity
--hash join is that the join operator can only return true for pairs of left and right values that hash to the same hash code
--merge on equality conditions and ordered
-- hash as merge but on hashable ie non ordered data
SELECT tablename, indexname, indexdef -- doees isolate the index name
FROM
    pg_indexes
WHERE
    schemaname = 'public' and tablename= 'payments'
ORDER BY
    tablename, indexname;
--index prop from pg_index view	and pages, tuples
SELECT relname as tablename, c.relpages, c.reltuples,
          i.indisunique as uniq, i.indisclustered as clustered, i.indisvalid as valid,
          pg_catalog.pg_get_indexdef(i.indexrelid, 0, true) as create_statement
          FROM pg_class c JOIN pg_index i on c.oid = i.indrelid
          WHERE c.relname = 'payments';
--index usage pg_stat_user_indexes : Same as pg_stat_all_indexes, except that only indexes on user tables are shown.
SELECT indexrelname, idx_scan, idx_tup_read, idx_tup_fetch 
FROM pg_stat_user_indexes 
WHERE relname = 'posts'; -- table posts

--update stat
ANALYZE posts; -- tsql UPDATE STATISTICS posts
--current stat in pg_stats - sys.dm_db_index_usage_stats with tsql
SELECT tablename, attname, n_distinct, most_common_vals,most_common_freqs,correlation,  avg_width, null_frac, histogram_bounds
          FROM pg_stats
          WHERE tablename = 'posts'; --- most_common_freqs * tuples in tables = tuples for a value od a column




