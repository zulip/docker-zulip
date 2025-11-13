# Compose: Getting started

1. Clone the repository:

   ```bash
   git clone https://github.com/zulip/docker-zulip.git
   cd docker-zulip
   ```

1. Configure the server settings; see {doc}`compose-settings`.

1. Configure {doc}`compose-ssl`.

1. Boot your Zulip installation for the first time, with:

   ```bash
   docker compose pull
   docker compose run --rm zulip app:init
   ```

   This will boot all of Zulip's dependencies, then verify the configuration and
   perform the initial database configuration. After a minute or two, the
   configuration should complete, ending with:

   ```
   === End Initial Configuration Phase ===
   ```

   If the output does not end with that, read the output carefully for warnings
   or errors.

1. Now that we know configuration completed successfully, you can start Zulip:

   ```bash
   docker compose up zulip --wait
   ```

1. Generate a link to create a new organization:

   ```bash
   ./manage.py generate_realm_creation_link
   ```

1. Open that link in a browser to complete the organization creation steps and
   log in.

   If you elected to use a self-signed certificate, your browser will require
   that you click past a security warning.

   If you see other errors related to your TLS configuration, you may need to
   revisit {doc}`compose-ssl`; after making any changes, re-run:

   ```bash
   docker compose up --wait
   ```

## Next steps

- Learn how to [get your organization
  started](https://zulip.com/help/moving-to-zulip) using Zulip at its best.
- {doc}`compose-incoming-email`

## See also

- {doc}`/manual/docker-compose`
- {doc}`compose-settings`
- {doc}`compose-ssl`
- {doc}`compose-secrets`
