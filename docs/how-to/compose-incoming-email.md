# Compose: Incoming email

The Docker image exposes port 25, which is already configured with Zulip's
incoming email server; the Docker Compose configuration defaults to publishing
that on port 25.

1. Determine the publicly-accessible hostname where that port 25 is exposed; in
   this example, we will use `hostname.example.com`. This may or may not be the
   same as `SETTING_EXTERNAL_HOST`.

1. Decide what email domain to use for the gateway; for this example, we will
   use `emaildomain.example.com`.

1. Using your DNS provider, create a DNS `MX` (mail exchange) record configuring
   email for `emaildomain.example.com` to be processed by the
   publicly-accessible hostname of the Docker host publishing port 25. You can
   check your work using this command:

   ```console
   $ dig +short emaildomain.example.com -t MX
   1 hostname.example.com
   ```

1. Edit `compose.override.yaml`, and set `SETTING_EMAIL_GATEWAY_PATTERN` to
   `%s@emaildomain.example.com`:

   ```yaml
   services:
     zulip:
       environment:
         SETTING_EMAIL_GATEWAY_PATTERN: "%s@emaildomain.example.com"
   ```

1. Start the container deployment with `docker compose up`.

## See also

- {doc}`zulip:production/email-gateway`
