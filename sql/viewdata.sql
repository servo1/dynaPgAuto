	    with view_columns as (
	        select
	            c.oid as view_oid,
	            a.attname::information_schema.sql_identifier as column_name
	        from pg_attribute a
	        join pg_class c on a.attrelid = c.oid
	        join pg_namespace nc on c.relnamespace = nc.oid
	        where
	            not pg_is_other_temp_schema(nc.oid)
	            and a.attnum > 0
	            and not a.attisdropped
	            and (c.relkind = 'v'::"char")
	            and nc.nspname not in ('information_schema', 'pg_catalog')
	    ),
	    view_column_usage as (
	        select distinct
	            v.oid as view_oid,
	            nv.nspname::information_schema.sql_identifier as view_schema,
	            v.relname::information_schema.sql_identifier as view_name,
	            nt.nspname::information_schema.sql_identifier as table_schema,
	            t.relname::information_schema.sql_identifier as table_name,
	            a.attname::information_schema.sql_identifier as column_name,
	            pg_get_viewdef(v.oid)::information_schema.character_data as view_definition
	        from pg_namespace nv
	        join pg_class v on nv.oid = v.relnamespace
	        join pg_depend dv on v.oid = dv.refobjid
	        join pg_depend dt on dv.objid = dt.objid
	        join pg_class t on dt.refobjid = t.oid
	        join pg_namespace nt on t.relnamespace = nt.oid
	        join pg_attribute a on t.oid = a.attrelid and dt.refobjsubid = a.attnum

	        where
	            nv.nspname not in ('information_schema', 'pg_catalog')
	            and v.relkind = 'v'::"char"
	            and dv.refclassid = 'pg_class'::regclass::oid
	            and dv.classid = 'pg_rewrite'::regclass::oid
	            and dv.deptype = 'i'::"char"
	            and dv.refobjid <> dt.refobjid
	            and dt.classid = 'pg_rewrite'::regclass::oid
	            and dt.refclassid = 'pg_class'::regclass::oid
	            and (t.relkind = any (array['r'::"char", 'v'::"char", 'f'::"char"]))
	    ),
	    candidates as (
	        select
	            vcu.*,
	            (
	                select case when match is not null then coalesce(match[8], match[7], match[4]) end
	                from regexp_matches(
	                    CONCAT('SELECT ', SPLIT_PART(vcu.view_definition, 'SELECT', 2)),
	                    CONCAT('SELECT.*?((',vcu.table_name,')|(\w+))\.(', vcu.column_name, ')(\s+AS\s+("([^"]+)"|([^, \n\t]+)))?.*?FROM.*?(',vcu.table_schema,'\.|)(\2|',vcu.table_name,'\s+(as\s)?\3)'),
	                    'nsi'
	                ) match
	            ) as view_column_name
	        from view_column_usage as vcu
	    )
	    select
	        c.table_schema,
	        c.table_name,
	        c.column_name as table_column_name,
	        c.view_schema,
	        c.view_name,
	        c.view_column_name
	    from view_columns as vc, candidates as c
	    where
	        vc.view_oid = c.view_oid
	        and vc.column_name = c.view_column_name
	    order by c.view_schema, c.view_name, c.table_name, c.view_column_name;
