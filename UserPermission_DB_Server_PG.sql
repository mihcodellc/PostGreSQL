--details on permissions on each object https://www.postgresql.org/docs/current/ddl-priv.html

-- roles "UserPermission_DB_Server_PG" 
/* inspecting ACL Access Control Lists  with function aclexplode on an object here domain */
WITH acl AS (
             SELECT relname,relacl,reltuples,
                    (aclexplode(relacl)).grantor,
                    (aclexplode(relacl)).grantee,
                    (aclexplode(relacl)).privilege_type,
                    CASE relkind 
			    WHEN 'r' THEN 'ordinary table' 
			    WHEN 'v' THEN 'view' 
			    WHEN 'm' THEN 'materialized view' 
			    WHEN 'S' THEN 'sequence' 
			    WHEN 'f' THEN 'foreign table'
			    when 'c' then 'composite type'
			    when 't' then 'TOAST table'
			    when 'p' then 'partitioned table'
			    when 'i' then 'index'
			    when 'I' then 'partitioned index'
		    else cast(C.relkind as char(1)) -- 'o' refers to other
		    END as Type, n.nspname as  schema_name, n.nspacl as namespace_priv_list, C.relowner, C.relkind
            FROM pg_class C
LEFT JOIN pg_namespace N
	ON (N.oid = C.relnamespace) 
)
         SELECT CURRENT_CATALOG,schema_name, acl.relname, g.rolname AS grantee,
                acl.privilege_type AS permission,
                gg.rolname AS grantor, acl.relacl, acl.reltuples, acl.Type, o.rolname
         FROM acl
         JOIN pg_roles g ON g.oid = acl.grantee
         JOIN pg_roles gg ON gg.oid = acl.grantor
	 JOIN pg_roles o on acl.relowner = o.oid
         where (acl.privilege_type = 'USAGE' and acl.schema_name = 'dbo') 
			or (cast(acl.namespace_priv_list as varchar(200)) ~ 'mbello') 
			or (acl.relname = 'domain')
	-- and acl.relkind::char(1) = 'v'
         order by g.rolname
--**count permissions by role	
-- SELECT g.rolname AS grantee,
--                 acl.privilege_type AS permission, count(*)
										  
																		 
--          FROM acl
--          JOIN pg_roles g ON g.oid = acl.grantee
--          JOIN pg_roles gg ON gg.oid = acl.grantor
--          --where (g.rolname ~ 'dprober') 
-- 	group by g.rolname, acl.privilege_type 																		   
--          order by g.rolname		 

--owners of tables, proc/functions
select distinct a.rolname, rolcanlogin,  rolsuper, rolcatupdate/*, relacl*/ from pg_authid a
 join pg_class c on a.oid = c.relowner 


select distinct a.rolname, rolcanlogin,  rolsuper, rolcatupdate, p.proacl from pg_authid a
 join pg_proc p on a.oid = p.proowner 

--role with members by role
select a.rolname roleGroup, u.rolcanlogin, u.rolsuper, u.rolcatupdate, u.rolname ismemberOfroleGroup, g.rolname as grantor   
from pg_auth_members m
join pg_authid a on a.oid = m.roleid
join pg_authid u on u.oid = m.member
join pg_authid g on g.oid = m.grantor
order by  a.rolname

--role with members by members
select u.rolname ismemberOfroleGroup, a.rolname roleGroup,
       shobj_description(u.oid, 'pg_authid') itsComment, obj_description(u.oid) as otherDesc, g.rolname as grantor,
       shobj_description(g.oid, 'pg_authid') Grantor_Desc, u.rolcanlogin, u.rolsuper, u.rolcreaterole, u.rolcreatedb
from pg_auth_members m
join pg_authid a on a.oid = m.roleid
join pg_authid u on u.oid = m.member
join pg_authid g on g.oid = m.grantor
--where u.rolname = 'dprober'::name
order by  ismemberOfroleGroup, roleGroup

	--SELECT  g.rolname AS grantee, shobj_description(g.oid, 'pg_authid') itsComment, obj_description(g.oid) as otherDesc,
        --        --(select rolname from pg_roles r where r.oid = m.roleid limit 1) as memberOfRole,
        --        gr.rolname as grp_name ,
        --       g.rolcanlogin, g.rolsuper,g.rolcreaterole, g.rolcreatedb
        -- FROM pg_roles g
        -- LEFT JOIN pg_auth_members m ON m.member = g.oid
        --left join pg_roles gr on gr.oid = m.roleid
        -- where g.rolname = 'dprober'::name
	

--role without members  
select a.rolname roleGroup, a.rolcanlogin, a.rolsuper, a.rolcatupdate, ''  ismemberOfroleGroup
from pg_authid a
where not exists (select 1/0 from pg_auth_members m where m.roleid = a.oid)
order by roleGroup



--full priv table, schema, db, functions levels
-- Combined User Permissions View
WITH acl AS (
    -- Tables, views, materialized views, foreign tables
    SELECT
        c.relname,
        c.relacl,
        c.reltuples,
        (aclexplode(c.relacl)).grantor,
        (aclexplode(c.relacl)).grantee,
        (aclexplode(c.relacl)).privilege_type,
        CASE c.relkind
            WHEN 'r' THEN 'ordinary table'
            WHEN 'v' THEN 'view'
            WHEN 'm' THEN 'materialized view'
            WHEN 'S' THEN 'sequence'
            WHEN 'f' THEN 'foreign table'
            WHEN 'c' THEN 'composite type'
            WHEN 't' THEN 'TOAST table'
            WHEN 'p' THEN 'partitioned table'
            WHEN 'i' THEN 'index'
            WHEN 'I' THEN 'partitioned index'
            ELSE cast(c.relkind as char(1))
        END AS Type,
        n.nspname AS schema_name,
        n.nspacl AS namespace_priv_list,
        c.relowner,
        c.relkind
    FROM pg_class c
    LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relacl IS NOT NULL

    UNION ALL

    -- Schemas
    SELECT
        n.nspname AS relname,
        n.nspacl AS relacl,
        NULL::bigint AS reltuples,
        (aclexplode(n.nspacl)).grantor,
        (aclexplode(n.nspacl)).grantee,
        (aclexplode(n.nspacl)).privilege_type,
        'schema' AS Type,
        n.nspname AS schema_name,
        n.nspacl AS namespace_priv_list,
        n.nspowner AS relowner,
        NULL::"char" AS relkind
    FROM pg_namespace n
    WHERE n.nspacl IS NOT NULL

    UNION ALL

    -- Databases
    SELECT
        d.datname AS relname,
        d.datacl AS relacl,
        NULL::bigint AS reltuples,
        (aclexplode(d.datacl)).grantor,
        (aclexplode(d.datacl)).grantee,
        (aclexplode(d.datacl)).privilege_type,
        'database' AS Type,
        NULL::text AS schema_name,
        NULL::aclitem[] AS namespace_priv_list,
        d.datdba AS relowner,
        NULL::"char" AS relkind
    FROM pg_database d
    WHERE d.datacl IS NOT NULL

    UNION ALL

    -- Functions
    SELECT
        p.proname AS relname,
        p.proacl AS relacl,
        NULL::bigint AS reltuples,
        (aclexplode(p.proacl)).grantor,
        (aclexplode(p.proacl)).grantee,
        (aclexplode(p.proacl)).privilege_type,
        'function' AS Type,
        n.nspname AS schema_name,
        NULL::aclitem[] AS namespace_priv_list,
        p.proowner AS relowner,
        NULL::"char" AS relkind
    FROM pg_proc p
    LEFT JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE p.proacl IS NOT NULL
)
SELECT
    CURRENT_CATALOG,
    acl.schema_name,
    acl.relname,
    g.rolname AS grantee,
    acl.privilege_type AS permission,
    gg.rolname AS grantor,
    acl.relacl,
    acl.reltuples,
    acl.Type,
    o.rolname AS owner,
    acl.relkind
FROM acl
JOIN pg_roles g ON g.oid = acl.grantee
JOIN pg_roles gg ON gg.oid = acl.grantor
JOIN pg_roles o ON o.oid = acl.relowner
--WHERE schema_name = 'public'
ORDER BY
    Type, schema_name, relname, grantee, permission;


or



-- User Permissions Across All Levels (PostgreSQL 9.3 compatible)
WITH acl AS (
    -- Tables, views, materialized views, sequences, foreign tables
    SELECT
        c.relname,
        c.relacl,
        c.reltuples,
        (aclexplode(c.relacl)).grantor,
        (aclexplode(c.relacl)).grantee,
        (aclexplode(c.relacl)).privilege_type,
        CASE c.relkind
            WHEN 'r' THEN 'ordinary table'
            WHEN 'v' THEN 'view'
            WHEN 'm' THEN 'materialized view'
            WHEN 'S' THEN 'sequence'
            WHEN 'f' THEN 'foreign table'
            WHEN 'c' THEN 'composite type'
            WHEN 't' THEN 'TOAST table'
            WHEN 'p' THEN 'partitioned table'
            WHEN 'i' THEN 'index'
            WHEN 'I' THEN 'partitioned index'
            ELSE cast(c.relkind as char(1))
        END AS Type,
        n.nspname AS schema_name,
        n.nspacl AS namespace_priv_list,
        c.relowner,
        c.relkind
    FROM pg_class c
    LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relacl IS NOT NULL

    UNION ALL

    -- Schemas
    SELECT
        n.nspname AS relname,
        n.nspacl AS relacl,
        NULL::bigint AS reltuples,
        (aclexplode(n.nspacl)).grantor,
        (aclexplode(n.nspacl)).grantee,
        (aclexplode(n.nspacl)).privilege_type,
        'schema' AS Type,
        n.nspname AS schema_name,
        n.nspacl AS namespace_priv_list,
        n.nspowner AS relowner,
        NULL::"char" AS relkind
    FROM pg_namespace n
    WHERE n.nspacl IS NOT NULL

    UNION ALL

    -- Databases
    SELECT
        d.datname AS relname,
        d.datacl AS relacl,
        NULL::bigint AS reltuples,
        (aclexplode(d.datacl)).grantor,
        (aclexplode(d.datacl)).grantee,
        (aclexplode(d.datacl)).privilege_type,
        'database' AS Type,
        NULL::text AS schema_name,
        NULL::aclitem[] AS namespace_priv_list,
        d.datdba AS relowner,
        NULL::"char" AS relkind
    FROM pg_database d
    WHERE d.datacl IS NOT NULL

    UNION ALL

    -- Functions
    SELECT
        p.proname AS relname,
        p.proacl AS relacl,
        NULL::bigint AS reltuples,
        (aclexplode(p.proacl)).grantor,
        (aclexplode(p.proacl)).grantee,
        (aclexplode(p.proacl)).privilege_type,
        'function' AS Type,
        n.nspname AS schema_name,
        NULL::aclitem[] AS namespace_priv_list,
        p.proowner AS relowner,
        NULL::"char" AS relkind
    FROM pg_proc p
    LEFT JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE p.proacl IS NOT NULL

    UNION ALL

    -- Tablespaces
    SELECT
        t.spcname AS relname,
        t.spcacl AS relacl,
        NULL::bigint AS reltuples,
        (aclexplode(t.spcacl)).grantor,
        (aclexplode(t.spcacl)).grantee,
        (aclexplode(t.spcacl)).privilege_type,
        'tablespace' AS Type,
        NULL::text AS schema_name,
        NULL::aclitem[] AS namespace_priv_list,
        t.spcowner AS relowner,
        NULL::"char" AS relkind
    FROM pg_tablespace t
    WHERE t.spcacl IS NOT NULL

    UNION ALL

    -- Foreign servers
    SELECT
        s.srvname AS relname,
        s.srvacl AS relacl,
        NULL::bigint AS reltuples,
        (aclexplode(s.srvacl)).grantor,
        (aclexplode(s.srvacl)).grantee,
        (aclexplode(s.srvacl)).privilege_type,
        'foreign server' AS Type,
        NULL::text AS schema_name,
        NULL::aclitem[] AS namespace_priv_list,
        s.srvowner AS relowner,
        NULL::"char" AS relkind
    FROM pg_foreign_server s
    WHERE s.srvacl IS NOT NULL

    UNION ALL

    -- Procedural languages
    SELECT
        l.lanname AS relname,
        l.lanacl AS relacl,
        NULL::bigint AS reltuples,
        (aclexplode(l.lanacl)).grantor,
        (aclexplode(l.lanacl)).grantee,
        (aclexplode(l.lanacl)).privilege_type,
        'language' AS Type,
        NULL::text AS schema_name,
        NULL::aclitem[] AS namespace_priv_list,
        l.lanowner AS relowner,
        NULL::"char" AS relkind
    FROM pg_language l
    WHERE l.lanacl IS NOT NULL
)
SELECT
    CURRENT_CATALOG,
    acl.schema_name,
    acl.relname,
    g.rolname AS grantee,
    acl.privilege_type AS permission,
    gg.rolname AS grantor,
    acl.relacl,
    acl.reltuples,
    acl.Type,
    o.rolname AS owner,
    acl.relkind
FROM acl
JOIN pg_roles g ON g.oid = acl.grantee
JOIN pg_roles gg ON gg.oid = acl.grantor
JOIN pg_roles o ON o.oid = acl.relowner
ORDER BY
    Type, schema_name, relname, grantee, permission;

