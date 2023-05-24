
--	execute as login in tsql equivalent
set role to mbello

--look permission on a table to know ACL then define waht to grant

ALTER ROLE mmiller NOLOGIN;
ALTER ROLE mmiller CREATEROLE CREATEDB;

create user mrigdon with PASSWORD 'mE!UsRdm1_)20RM$22' valid until 'infinity';
COMMENT ON ROLE mrigdon IS 'Millie Rigdon, Quality Assurance Engineer';
-- GRANT db_reader TO mrigdon;
-- GRANT devops_rx TO mrigdon; -- read and execute --prod
-- grant clientserv_ro to ctrowbridge; -- readonly
--GRANT medrx_rw TO mrigdon; -- dev1
-- GRANT db_datawriter TO mrigdon; --payer dev
GRANT pgdev TO mrigdon; --payer dev, payer UAT
-- GRANT db_datareader TO mrigdon; --payer prod
-- GRANT pgdev_ro TO mrigdon; --payer prod


--on dev1
create user sstauffer with PASSWORD 'sE!UsFsm1_)20RM$22' valid until 'infinity';
COMMENT ON ROLE sstauffer IS 'Scott Stauffer, Software Engineer';
GRANT medrx_rw TO sstauffer;

--on prod1
create user sstauffer with PASSWORD 'c!UsUbm1_)20RM$22' valid until 'infinity';
COMMENT ON ROLE sstauffer IS 'Camon Buller, Software Engineer';
GRANT db_reader TO sstauffer;
GRANT devops_rx TO cmcclain; -- read and execute 

create user nvu with PASSWORD 'n!UsVb01_)20RM$23' valid until 'infinity';
COMMENT ON ROLE nvu IS 'Nhu Vu, Customer Support Rep';
GRANT clientserv_ro TO nvu; --READ ONLY

--read and execute role on prod1
create role devops_rx;
grant execute on all functions in schema public to devops_rx;
grant select  on all tables in schema public to devops_rx;

--on prod payer solution
alter user mmiller with PASSWORD 'L1t3immTm$2012' valid until 'infinity';
COMMENT ON ROLE sstauffer IS 'Matt Weers, QA';
GRANT db_datawriter TO sstauffer;
-- READONLY > GRANT db_datareaderTO mmiller;

grant select ON ALL TABLES IN SCHEMA public to medrx_ro;
grant EXECUTE ON ALL FUNCTIONS /*depend version PROCEDURES | ROUTINES*/ IN SCHEMA public to medrx_ro; --
grant select on that new/altered view to pgdev and pgdev_ro and svc_payersolution.

Solution UAT 11.60
alter table remittance_query_view owner to postgres;
grant select on remittance_query_view to pgdev_ro;
grant delete, insert, references, select, update on remittance_query_view to svc_payersolution;
grant select on remittance_query_view to db_datareader;
grant delete, insert, select, update on remittance_query_view to db_datawriter;

Prod Payer SOlution
alter table remittance_query_view owner to postgres;
grant select on remittance_query_view to pgdev_ro;
grant select on remittance_query_view to pgdev;
grant select on remittance_query_view to svc_payersolution;
grant select on remittance_query_view to db_datareader;
grant select on remittance_query_view to db_datawriter;

alter USER mbello WITH PASSWORD 'xxxxxxxxxxxxxxxxxxxxxx' VALID UNTIL '2022-10-31';

grant medrx_rw to mbello;

grant db_reader to mbello;

comment on role mbello is 'Monktar Bello, DBA';

drop user mbello;


create user mbellotest;

alter role mbellotest with nosuperuser;

alter role mbellotest with createdb;

alter role mbellotest with createrole;


SELECT * FROM information_schema.role_routine_grants

    SELECT * FROM information_schema.table_privileges 	

	alter role mbello with superuser

	alter role mbello with nosuperuser -- superuser, password, createdb, createrole, inherit, login, nologin...
	SELECT * FROM pg_authid /*pg_roles*/ WHERE rolname = 'luca'
	SELECT r.rolname, g.rolname AS group, m.admin_option AS is_admin
          FROM pg_auth_members m
               JOIN pg_roles r ON r.oid = m.member
               JOIN pg_roles g ON g.oid = m.roleid
          ORDER BY r.rolname;



--inspect privileges on different objects of databases
	SELECT distinct privilege_type FROM information_schema.table_privileges where grantee = 'casharc_ro';
SELECT distinct privilege_type FROM information_schema.role_table_grants where table_name not like 'pg_%' and grantee = 'casharc_ro'; --included views
SELECT * FROM information_schema.role_routine_grants where grantee = 'casharc_ro';
SELECT * FROM information_schema.role_udt_grants where grantee = 'casharc_ro';
select * from information_schema.role_usage_grants where grantee = 'casharc_ro';
select * from information_schema.views where table_name not like 'pg_%'; --included system views


For Postgres, and only for cases where privs were assigned directly to their account instead of via a role...
--tables, sequences, functions in each schema
replace functions with in 
SELECT concat('revoke all privileges on all functions in schema  ', n.nspname , ' from pmcaskill; ')
FROM pg_class C
LEFT JOIN pg_namespace N
	ON (N.oid = C.relnamespace)
WHERE nspname NOT IN ('pg_catalog', 'information_schema')
GROUP BY nspname;

--revoke all privileges on all tables in schema public from myUser;;
--revoke all privileges on all sequences in schema public from myUser;
--revoke all privileges on all functions in schema public from myUser;

----sequence & Table share the same owner
alter table prod.host_prefs_base owner to postgres;
alter sequence prod.host_prefs_base owner to postgres;
or simply 
REASSIGN OWNED BY zgeyser TO postgres;
--then
drop role myUser;

