# MySQL Credentials submodule for DB Credential

This submodule creates a MySQL user with a generated password and grants it access to a database. Its outputs are
shaped to be passed straight into the `db_credential` module's `credentials` variable,
which stores them in Secrets Manager.

It uses the [petoju/mysql](https://registry.terraform.io/providers/petoju/mysql/latest/docs) provider, which you
configure in your own root module.

The RDS Aurora module uses this for you when you pass `credentials` to it. To use it directly, see the
`db_credential` module's readme for an example.
