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
		    else relkind
		    END as Type, n.nspname as  schema_name, n.nspacl as namespace_priv_list
            FROM pg_class C
LEFT JOIN pg_namespace N
	ON (N.oid = C.relnamespace) 
)
         SELECT acl.relname, g.rolname AS grantee,
                acl.privilege_type AS permission,
                gg.rolname AS grantor, acl.relacl, acl.reltuples, acl.Type
         FROM acl
         JOIN pg_roles g ON g.oid = acl.grantee
         JOIN pg_roles gg ON gg.oid = acl.grantor
         where (acl.privilege_type = 'USAGE' and acl.schema_name = 'rmsadmin') 
			or (cast(acl.namespace_priv_list as varchar(200)) ~ 'kcrawford') 
			or (acl.relname = 'domain')
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
