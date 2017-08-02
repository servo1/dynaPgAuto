var pg = require('dynaPgConn').connect();
var fs = require('fs');
var path = require('path');
//files containing sql

(function () {
	var pgauto = {};
	pgauto.sqlFiles = {};
	pgauto.schemas = {};
	pgauto.relations = {};
	pgauto.pgfuncs = {};
	pgauto.views = {};

	pgauto.init = function (cb) {
		var sqlFolder = path.join(__dirname, './sql/');
		ge("here we are!", sqlFolder);

		fs.readdir(sqlFolder, function (err, items) {
			forEach(items, function (item, ind, ecb) {
				wf([
					function (wcb) {
						fs.readFile(sqlFolder + '/' + item, "utf8", wcb);
					},
					function (fdata, wcb) {
						pgauto.sqlFiles[item] = fdata;
						wcb();
					},
					function (wcb) {
						pg.query(pgauto.sqlFiles[item], [], wcb);
					},
					function (res, wcb) {
						var processor = item.replace('.sql', '');
						pgauto.processRes(processor, res.rows, wcb);
					}
				], ecb);
			}, function(er, res){
				if (typeof cb == "function") cb(er, pgauto.schemas);
			});
		});
	}

	pgauto.processRes = function (processor, data, pcb) {
		if (typeof processor == "string" && typeof pgauto[processor] == "function") {
			var resprocess = pgauto[processor];
			forEach(data, resprocess, pcb);
		} else cb("no processor for " + processor);
	}

	pgauto.baseObj = function () {
		return {
			properties: {},
			type: "object",
			title: "",
			required: [],
			insertable: false,
			primaryKeys: []
		}
	}

	pgauto.tablefields = function (row, ind, cb) {
		if (typeof pgauto.schemas[row.table_name] !== "object") pgauto.schemas[row.table_name] = new pgauto.baseObj();
		var cobj = pgauto.schemas[row.table_name];
		cobj.title = row.table_name;
		if (row.nullable == false) cobj.required.push(row.name);
		if (typeof cobj.properties[row.name] !== "object") cobj.properties[row.name] = {};
		cobj.properties[row.name].type = row.col_type,
		cobj.properties[row.name].max_len = row.max_len,
		cobj.properties[row.name].position = row.position,
		cobj.properties[row.name].updatable = row.updatedable,
		cobj.properties[row.name].precision = row.precision,
		cobj.properties[row.name].enum = row.enum

		if (row.name !== "id") cobj.properties[row.name].default = row.default_value;
		cb();
	}

	pgauto.relatedcolumns = function (row, ind, cb) {
		if (typeof pgauto.schemas[row.table_name] !== "object") pgauto.schemas[row.table_name] = new pgauto.baseObj();
		var cobj = pgauto.schemas[row.table_name];
		var fname = row.columns.replace('{', '').replace('}', '');
		if (typeof cobj.properties[fname] !== "object") cobj.properties[fname] = {};
		if (typeof cobj.properties[fname].refs !== "object") cobj.properties[fname].refs = {};
		cobj.properties[fname].refs = {
			table: row.foreign_table_name,
			column: row.foreign_columns.replace('{', '').replace('}', '')
		}
		cb();
		var examples = `
		relatedcolumns
		{ table_schema: 'public',
					 table_name: 'apps',
					 columns: '{userid}',
					 foreign_table_schema: 'public',
					 foreign_table_name: 'users',
					 foreign_columns: '{id}' }

		`
	}

	pgauto.pgfuncs = function (row, ind, cb) {
		cb();
		var examples = `
		pgfuncs
		{ proc_name: 'updateupdatedat',
					 args: '',
					 rettype_schema: 'pg_catalog',
					 rettype_name: 'trigger',
					 rettype_is_setof: false,
					 rettype_typ: 'p',
					 provolatile: 'v' }

		`
	}
	pgauto.schemadata = function (row, ind, cb) {
		if (typeof pgauto.schemas[row.table_name] !== "object") pgauto.schemas[row.table_name] = new pgauto.baseObj();
		pgauto.schemas[row.table_name].insertable = row.insertable;

		cb();
		var examples = `
		schemadata
		{ table_schema: 'public', table_name: 'css', insertable: true },`
	}

	pgauto.ownerdata = function (row, ind, cb) {
		if (typeof pgauto.schemas[row.table_name] !== "object") pgauto.schemas[row.table_name] = new pgauto.baseObj();
		var cobj = pgauto.schemas[row.table_name];
		cobj.primaryKeys.push(row.column_name);
		cb();
		var exampledata = `ownerdata  //basically lists primary keys for each table
		{ table_schema: 'public',
					table_name: 'cssdeps',
					column_name: 'cssid' },
				{ table_schema: 'public',
					table_name: 'cssdeps',
					column_name: 'depid' },
				{ table_schema: 'public',
					table_name: 'webroutes_fonts',
					column_name: 'webrouteid' },
				{ table_schema: 'public',
					table_name: 'webroutes_fonts',
					column_name: 'fontid' }
		`;
	}
	pgauto.viewdata = function (row, ind, cb) {
		if (typeof cb !== "function") ge(row, ind, cb);
		else cb();
		var examples = `
		`
	}


	if (typeof module !== "undefined" && ('exports' in module)) {
		module.exports = pgauto;
	}

})();


//examples
