# PostgreSQL Credentials submodule for DB Credential

This submodule creates a PostgreSQL login role with a generated password and grants it access to a database schema.
Its outputs are shaped to be passed straight into the main module's `credentials` variable.

It uses the [cyrilgdn/postgresql](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs) provider,
which you configure in your own root module. On RDS/Aurora, set `superuser = false` in the provider config since the
master user isn't a real superuser.

PostgreSQL grants on tables only cover tables that already exist. If your migrations create tables after this runs, set
`objects_owner` to the role your migrations run as so new tables get the same grants.

See the main module's readme for example usage.
