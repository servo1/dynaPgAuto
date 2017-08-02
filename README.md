# dynaPgAuto

Requires pg, dynaPgConn, dynaUtils
(sorry haven't placed a packages.json yet)

All you need to do is have an active postgres connection with dynaPgConn.

```javascript
var pgconn = require('dynaPgConn');
var pgauto = require('dynaPgAuto');

pgconn.connect({
	user: 'postgres',
	host: 'localhost',
	database: 'mydb',
	password: 'mypass',
	port: 5432,
}, function (er, res) {
	pgauto.init( function (er, res){
    console.log(er, res);
  });
});

```

The SQL that is utilized within the sql directory may require one modification:  change pgfuncs.sql and set your appropriate schema.  

With the above code, you will find a near valid JSON schema is produced.  

Most of the SQL is taken from https://github.com/begriffs/postgrest/tree/master/src/PostgREST  

The SQL is extracted from the queries that are generated during the initial setup.  

Part of the purpose of this is to create a similar logical layer as postgrest but with Node as the layer in between.  In the long run, this will be apart of a Node, Postgres and Redis solution.  

This is working but definitely early alpha stages.

