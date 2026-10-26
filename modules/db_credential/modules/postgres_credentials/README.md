# PostgreSQL Credentials submodule for DB Credential

This submodule creates a PostgreSQL login role with a generated password and grants it access to a database schema.
Its outputs are shaped to be passed straight into the `db_credential` module's `credentials` variable,
which stores them in Secrets Manager.

It uses the [cyrilgdn/postgresql](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs) provider,
which you configure in your own root module. On RDS/Aurora, set `superuser = false` in the provider config since the
master user isn't a real superuser.

PostgreSQL grants on tables only cover tables that already exist. If your migrations create tables after this runs, set
`objects_owner` to the role your migrations run as so new tables get the same grants.

The RDS Aurora module uses this for you when you pass `credentials` to it. To use it directly, see the
`db_credential` module's readme for an example.
