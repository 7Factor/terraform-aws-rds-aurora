# MySQL Credentials submodule for DB Credential

This submodule creates a MySQL user with a generated password and grants it access to a database. Its outputs are
shaped to be passed straight into the main module's `credentials` variable.

It uses the [petoju/mysql](https://registry.terraform.io/providers/petoju/mysql/latest/docs) provider, which you
configure in your own root module.

See the main module's readme for example usage.
