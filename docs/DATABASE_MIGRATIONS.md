# Database revision 2

Update: the local PostgreSQL cutover is complete and verified; see [PostgreSQL setup](POSTGRESQL_SETUP.md). The older SQLite-only verification statements below describe the earlier multi-user implementation phase.


The existing SQLite/SQLAlchemy database is retained. Revision 2 adds `login_accounts`, `account_invitations` and `schema_revisions`; it does not recreate legacy tables or rewrite task JSON. New identity tables have unique participant foreign keys. SQLite foreign-key checking is enabled for new connections. Existing logical ownership columns are unchanged.

The supported mechanism is a **small additive bootstrap revision**, implemented in [db.py](../outputs/backend/app/db.py), not a general Alembic history. SQLAlchemy creates missing tables idempotently and records revision 2 after that succeeds. Both application startup and the explicit command use this same function. If interrupted before the ledger entry, rerunning completes missing objects without replacing existing rows. DDL atomicity and online upgrades across deployment workers are not promised.

From `outputs/backend`, after stopping the local server and making a private backup:

```powershell
# Install exact required packages, including Argon2.
.\.venv\Scripts\python.exe -m pip install -r requirements-lock.txt
.\.venv\Scripts\python.exe -m app.migrate
```

Expected output includes revision `2`. Do not delete the database as a migration step. For SQLite, stop all writers before copying the database and its journal/WAL state or use SQLite's backup API; keep backups outside Git and test restoration in a temporary location. No automatic downgrade is provided because it could destroy login identities.

`test_additive_migration_preserves_legacy_account` builds an old participants table, adds revision 2 twice and verifies its ID, assignment and token hash remain unchanged. Existing optional task fields retain their model defaults and compatibility tests. All executed migration/database checks used temporary SQLite databases. The running existing database was not migrated during implementation.

PostgreSQL remains configurable through SQLAlchemy/psycopg but was not tested in this change. Before production: establish managed migration ordering, backup/restore validation, PostgreSQL constraints/concurrency tests, a rollback strategy and retention procedures. Future changes to existing columns require explicit versioned migrations; `create_all` does not alter those columns.
