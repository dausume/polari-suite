# SQL keyword guard (2026-10-30)

His asks (2026-10-30): "we should probably make a guard that safely protects and/or wraps protected keywords so they can be used without breaking sql";
"we also need to ensure it is notated when it happens so when they come back out of sql it still is the same"; "this should be an isolated piece of
functionality that clearly indicates it's purpose is to protect the database from keywords".

## The defect it closes
Row-class fields become column names. The sqlite adapter wrote them unquoted, so a field named `order`, `index`, `group`, `default`, `commit`, `case`,
`exists`, `when` or `where` made `CREATE TABLE` fail and the class was never persisted - one `[DB] FAILED to create table` boot line and nothing else.
Found while adding `SpiceRun` (field `where`); a scan of every class found **31 classes in 15 modules** (hwnocode, suiteapps, uno_core_demo, computelod,
pspp, zones, iso, vpn, cicd, mealoptions, cntfet, tensormath, security, cmod, sifet, board's `ConfigurationEvent.when`). MariaDB already backticked
(after `precision` broke `SimVariable`); sqlite did not.

## The guard - `polari-framework/polariDBmanagement/sql_keyword_guard.py`
One module whose only job is protecting the database from keyword names:
- `quote(name, dialect)` - THE identifier wrapper: sqlite `"name"`, MariaDB `` `name` ``; an embedded quote is doubled, so a name can never close the
  quoting (a hostile name is just a column). Every adapter's `quoteIdent` delegates here; table creation, the upsert, added columns, the single-row
  UPDATE and the scoped DELETE all go through it. EVERY name is wrapped, keyword or not - the wrapping is SQL syntax only.
- `is_keyword(name, dialect)` - sqlite: asked of sqlite itself (an unquoted probe column); MariaDB: its published reserved-word list (251 words,
  https://mariadb.com/kb/en/reserved-words/, page sha256 d1778760...).
- `note(name, table, dialect)` - the NOTATION: each keyword it protected, once per (table, name), with how it was written; one log line
  `[DB-KeywordGuard] Table.order is an SQL keyword in sqlite: written as "order", stored and read back as 'order'`; `guarded()` lists them.
- `check_roundtrip(table, declared, stored)` - the promise that a guarded name comes back out of SQL THE SAME: after `managedDB.makeSQLiteTable`, the
  column names the database reports must equal the class's field names exactly; a difference is reported (`broken()`), never silently renamed.

## Proof - `polariDBmanagement/selftest_sql_keyword_guard.py` (5 checks)
1. every row class (887, read by AST) creates its table and saves a row through the sqlite adapter; 2. the wrapping + escape (a hostile name survives
as a column); 3. the round trip for all 32 keyword fields: in and out under exactly their own name with their value; 4. the notation; 5. end to end
through `managedDB` (makeSQLiteTable / saveInstanceInDB / getAllInTable) with fields `order`, `when`, `index`.

`ConfigurationEvent.when` keeps its name (the guard makes it legal). `SpiceRun`'s field is `host` (a better name, not a workaround).
