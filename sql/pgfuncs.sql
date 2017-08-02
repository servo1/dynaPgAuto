	  SELECT p.proname as "proc_name",
	         pg_get_function_arguments(p.oid) as "args",
	         tn.nspname as "rettype_schema",
	         coalesce(comp.relname, t.typname) as "rettype_name",
	         p.proretset as "rettype_is_setof",
	         t.typtype as "rettype_typ",
	         p.provolatile
	  FROM pg_proc p
	    JOIN pg_namespace pn ON pn.oid = p.pronamespace
	    JOIN pg_type t ON t.oid = p.prorettype
	    JOIN pg_namespace tn ON tn.oid = t.typnamespace
	    LEFT JOIN pg_class comp ON comp.oid = t.typrelid
	  WHERE  pn.nspname = 'public'  
