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
