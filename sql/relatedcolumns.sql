	    SELECT ns1.nspname AS table_schema,
	           tab.relname AS table_name,
	           column_info.cols AS columns,
	           ns2.nspname AS foreign_table_schema,
	           other.relname AS foreign_table_name,
	           column_info.refs AS foreign_columns
	    FROM pg_constraint,
	       LATERAL (SELECT array_agg(cols.attname) AS cols,
	                       array_agg(cols.attnum)  AS nums,
	                       array_agg(refs.attname) AS refs
	                  FROM ( SELECT unnest(conkey) AS col, unnest(confkey) AS ref) k,
	                       LATERAL (SELECT * FROM pg_attribute
	                                 WHERE attrelid = conrelid AND attnum = col)
	                            AS cols,
	                       LATERAL (SELECT * FROM pg_attribute
	                                 WHERE attrelid = confrelid AND attnum = ref)
	                            AS refs)
	            AS column_info,
	       LATERAL (SELECT * FROM pg_namespace WHERE pg_namespace.oid = connamespace) AS ns1,
	       LATERAL (SELECT * FROM pg_class WHERE pg_class.oid = conrelid) AS tab,
	       LATERAL (SELECT * FROM pg_class WHERE pg_class.oid = confrelid) AS other,
	       LATERAL (SELECT * FROM pg_namespace WHERE pg_namespace.oid = other.relnamespace) AS ns2
	    WHERE confrelid != 0
	    ORDER BY (conrelid, column_info.nums)
