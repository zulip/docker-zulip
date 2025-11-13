# Compose: Using existing services

It is possible to use only parts of Zulip's Docker Compose configuration, and
use already-existing services (e.g. an external database) for other parts of the
deployment.

The external database must be accessible on the Docker network that contains the
rest of the Zulip services.

1. Create the `zulip` network:

   ```shell
   docker network create zulip
   ```

1. Update your external service (e.g. PostgreSQL server) to be accessible via
   the `zulip` network. How to do this will vary based on your deployment.

1. Create the user and database in the external service, if necessary.

1. Update `compose.override.yaml` to update the list of service dependencies,
   remove the service you will manage externally, and use the `zulip` network:

   ```yaml
   networks:
     zulip:
       external: true
   services:
     # Removes the "database" service entirely
     database: !reset null

     redis:
       networks:
         - zulip
     memcached:
       networks:
         - zulip
     rabbitmq:
       networks:
         - zulip
     zulip:
       networks:
         - zulip
       depends_on:
         # "database" has been removed from this set
         - memcached
         - rabbitmq
         - redis
       environment:
         SETTING_REMOTE_POSTGRES_HOST: "external-database-hostname"

         # These are the default names, but you may need to change them
         # based on your database's configuration.
         CONFIG_postgresql__database_user: "zulip"
         CONFIG_postgresql__database_name: "zulip"

         # various settings as usual..
   ```

1. Test that the container can connect to the database:

   ```shell
   docker compose run --rm app:managepy checks
   ```

1. Start the containers:

   ```shell
   docker compose up
   ```
