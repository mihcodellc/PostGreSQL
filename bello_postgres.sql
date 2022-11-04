﻿Amazon rds, 
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


*************ADMIN
--start db postgres by specifuing the data directory. good practive to log every command for trousbleshooting purpose
postgres -D /usr/local/pgsql/data > logfile
pg_ctl start -l logfile

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
 

--table size
select pg_size_pretty(pg_relation_size('accountnumber'));

select pg_size_pretty(pg_database_size('prod1'));
--db and size
select datname, datdba,pg_size_pretty(pg_database_size(datname))
from pg_database;

--describe table
EXPLAIN ANALYZE select * from information_schema.columns
where table_name = 'accountnumber' limit 1;
	EXPLAIN = estimate plan
	EXPLAIN ANALYZE = Actual plan
	EXPLAIN (ANALYZE, BUFFERS)
		disk IO
	EXPLAIN (ANALYZE, BUFFERS, VERBOSE) 
	visual
		https://www.pgmustard.com/ 
			needs json format
			explain (analyze, format json, buffers, verbose)
		https://explain.depesz.com/
		

SELECT * FROM pg_class WHERE relname = 'claim_data' -- relation ie class or plsql "\d schema.claim_data" or "\d+ schema.claim_data"
Select table_name, columns.column_name, columns.is_nullable, columns.data_type, columns.character_maximum_length from information_schema.columns where table_name = 'claim_data';


--search though postgre
-- You can do the same for views by changing "routines" to "views" or "tables" or "triggers"
SELECT routine_name,routine_catalog, routine_schema, routine_type,* FROM information_schema.routines -- 
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


PostgreSQL, users are referred to as login roles,

A login role is a role that has been assigned the CONNECT privilege.

each connection can have 
	one active transaction at a time and 
	one fully active statement at any time.
	
	SELECT current_database();
	SELECT inet_server_addr(), inet_server_port();
	SELECT version();
	
-- roles
create view role_routine_grants (grantor, grantee, specific_catalog, specific_schema, specific_name, routine_catalog, routine_schema,routine_name, privilege_type, is_grantable)
	SELECT * FROM information_schema.role_routine_grants
    SELECT * FROM information_schema.table_privileges 	