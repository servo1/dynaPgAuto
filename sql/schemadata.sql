SELECT
	n.nspname AS table_schema,
	c.relname AS table_name,
	c.relkind = 'r' OR (c.relkind IN ('v','f'))
	AND (pg_relation_is_updatable(c.oid::regclass, FALSE) & 8) = 8
	OR (EXISTS
		( SELECT 1
			FROM pg_trigger
			WHERE pg_trigger.tgrelid = c.oid
			AND (pg_trigger.tgtype::integer & 69) = 69) ) AS insertable
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('v','r','m')
	AND n.nspname NOT IN ('pg_catalog', 'information_schema')
GROUP BY table_schema, table_name, insertable
ORDER BY table_schema, table_name
