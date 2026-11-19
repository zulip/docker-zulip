# Compose: Configuring authentication methods

Set `ZULIP_AUTH_BACKENDS` to a comma-separated list of backend class names
without the `zproject.backends.` package prefix (e.g.,
`"EmailAuthBackend,GoogleAuthBackend"`). The Docker image adds this prefix
automatically. For example, configure the OIDC backend with
`GenericOpenIdConnectBackend`, not
`zproject.backends.GenericOpenIdConnectBackend`. This takes the place of
`SETTING_AUTHENTICATION_BACKENDS`.

## See also

- {doc}`zulip:production/authentication-methods`
- {doc}`/reference/environment-vars`
