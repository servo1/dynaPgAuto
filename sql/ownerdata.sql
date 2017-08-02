
	    /*
	    -- CTE to replace information_schema.table_constraints to remove owner limit
	    */
	    WITH tc AS (
	        SELECT current_database()::information_schema.sql_identifier AS constraint_catalog,
	            nc.nspname::information_schema.sql_identifier AS constraint_schema,
	            c.conname::information_schema.sql_identifier AS constraint_name,
	            current_database()::information_schema.sql_identifier AS table_catalog,
	            nr.nspname::information_schema.sql_identifier AS table_schema,
	            r.relname::information_schema.sql_identifier AS table_name,
	                CASE c.contype
	                    WHEN 'c'::"char" THEN 'CHECK'::text
	                    WHEN 'f'::"char" THEN 'FOREIGN KEY'::text
	                    WHEN 'p'::"char" THEN 'PRIMARY KEY'::text
	                    WHEN 'u'::"char" THEN 'UNIQUE'::text
	                    ELSE NULL::text
	                END::information_schema.character_data AS constraint_type,
	                CASE
	                    WHEN c.condeferrable THEN 'YES'::text
	                    ELSE 'NO'::text
	                END::information_schema.yes_or_no AS is_deferrable,
	                CASE
	                    WHEN c.condeferred THEN 'YES'::text
	                    ELSE 'NO'::text
	                END::information_schema.yes_or_no AS initially_deferred
	        FROM pg_namespace nc,
	            pg_namespace nr,
	            pg_constraint c,
	            pg_class r
	        WHERE nc.oid = c.connamespace AND nr.oid = r.relnamespace AND c.conrelid = r.oid AND (c.contype <> ALL (ARRAY['t'::"char", 'x'::"char"])) AND r.relkind = 'r'::"char" AND NOT pg_is_other_temp_schema(nr.oid)
	        /*--AND (pg_has_role(r.relowner, 'USAGE'::text) OR has_table_privilege(r.oid, 'INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER'::text) OR has_any_column_privilege(r.oid, 'INSERT, UPDATE, REFERENCES'::text))*/
	        UNION ALL
	        SELECT current_database()::information_schema.sql_identifier AS constraint_catalog,
	            nr.nspname::information_schema.sql_identifier AS constraint_schema,
	            (((((nr.oid::text || '_'::text) || r.oid::text) || '_'::text) || a.attnum::text) || '_not_null'::text)::information_schema.sql_identifier AS constraint_name,
	            current_database()::information_schema.sql_identifier AS table_catalog,
	            nr.nspname::information_schema.sql_identifier AS table_schema,
	            r.relname::information_schema.sql_identifier AS table_name,
	            'CHECK'::character varying::information_schema.character_data AS constraint_type,
	            'NO'::character varying::information_schema.yes_or_no AS is_deferrable,
	            'NO'::character varying::information_schema.yes_or_no AS initially_deferred
	        FROM pg_namespace nr,
	            pg_class r,
	            pg_attribute a
	        WHERE nr.oid = r.relnamespace AND r.oid = a.attrelid AND a.attnotnull AND a.attnum > 0 AND NOT a.attisdropped AND r.relkind = 'r'::"char" AND NOT pg_is_other_temp_schema(nr.oid)
	        /*--AND (pg_has_role(r.relowner, 'USAGE'::text) OR has_table_privilege(r.oid, 'INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER'::text) OR has_any_column_privilege(r.oid, 'INSERT, UPDATE, REFERENCES'::text))*/
	    ),
	    /*
	    -- CTE to replace information_schema.key_column_usage to remove owner limit
	    */
	    kc AS (
	        SELECT current_database()::information_schema.sql_identifier AS constraint_catalog,
	            ss.nc_nspname::information_schema.sql_identifier AS constraint_schema,
	            ss.conname::information_schema.sql_identifier AS constraint_name,
	            current_database()::information_schema.sql_identifier AS table_catalog,
	            ss.nr_nspname::information_schema.sql_identifier AS table_schema,
	            ss.relname::information_schema.sql_identifier AS table_name,
	            a.attname::information_schema.sql_identifier AS column_name,
	            (ss.x).n::information_schema.cardinal_number AS ordinal_position,
	                CASE
	                    WHEN ss.contype = 'f'::"char" THEN information_schema._pg_index_position(ss.conindid, ss.confkey[(ss.x).n])
	                    ELSE NULL::integer
	                END::information_schema.cardinal_number AS position_in_unique_constraint
	        FROM pg_attribute a,
	            ( SELECT r.oid AS roid,
	                r.relname,
	                r.relowner,
	                nc.nspname AS nc_nspname,
	                nr.nspname AS nr_nspname,
	                c.oid AS coid,
	                c.conname,
	                c.contype,
	                c.conindid,
	                c.confkey,
	                c.confrelid,
	                information_schema._pg_expandarray(c.conkey) AS x
	               FROM pg_namespace nr,
	                pg_class r,
	                pg_namespace nc,
	                pg_constraint c
	              WHERE nr.oid = r.relnamespace AND r.oid = c.conrelid AND nc.oid = c.connamespace AND (c.contype = ANY (ARRAY['p'::"char", 'u'::"char", 'f'::"char"])) AND r.relkind = 'r'::"char" AND NOT pg_is_other_temp_schema(nr.oid)) ss
	        WHERE ss.roid = a.attrelid AND a.attnum = (ss.x).x AND NOT a.attisdropped
	        /*--AND (pg_has_role(ss.relowner, 'USAGE'::text) OR has_column_privilege(ss.roid, a.attnum, 'SELECT, INSERT, UPDATE, REFERENCES'::text))*/
	    )
	    SELECT
	        kc.table_schema,
	        kc.table_name,
	        kc.column_name
	    FROM
	        /*
	        --information_schema.table_constraints tc,
	        --information_schema.key_column_usage kc
	        */
	        tc, kc
	    WHERE
	        tc.constraint_type = 'PRIMARY KEY' AND
	        kc.table_name = tc.table_name AND
	        kc.table_schema = tc.table_schema AND
	        kc.constraint_name = tc.constraint_name AND
	        kc.table_schema NOT IN ('pg_catalog', 'information_schema')
