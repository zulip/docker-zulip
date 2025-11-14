# Incoming email

The Docker image exposes port 25, which is already configured with Zulip's
incoming email server. To use it, publish port 25 of the Docker container, set
`SETTING_EMAIL_GATEWAY_PATTERN`, and add an MX record to your DNS configuration
pointing to the Docker container's public hostname (or wherever you chose to
publicly expose its port 25).
