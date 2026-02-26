# Helm: Using existing services

By default, the Helm chart deploys PostgreSQL, RabbitMQ, Memcached, and Redis as
Bitnami subcharts. You can disable any or all of these subcharts to use
pre-existing external services instead.

## Using an external PostgreSQL server

1. Disable the bundled PostgreSQL subchart and configure the external server in
   your values file:

   ```yaml
   postgresql:
     enabled: false

   externalPostgresql:
     host: pg.example.com
     port: 5432
     user: zulip
     database: zulip
     password: your-pg-password
     sslmode: require
   ```

   The `sslmode` setting is optional and maps to the PostgreSQL `sslmode`
   connection parameter.

1. Ensure the external PostgreSQL server has the required extensions installed.
   Zulip needs the `pgroonga` and `tsearch_extras` extensions. The
   `zulip/zulip-postgresql` Docker image includes these, but a standard
   PostgreSQL server may not.

1. Create the `zulip` database and user on your external server before
   installing the chart.

## Using an external RabbitMQ server

```yaml
rabbitmq:
  enabled: false

externalRabbitmq:
  host: rabbitmq.example.com
  port: 5672
  user: zulip
  password: your-rabbitmq-password
```

## Using an external Memcached server

```yaml
memcached:
  enabled: false

externalMemcached:
  host: memcached.example.com
  port: 11211
  user: zulip
  password: your-memcached-password
```

## Using an external Redis server

```yaml
redis:
  enabled: false

externalRedis:
  host: redis.example.com
  port: 6379
  password: your-redis-password
```

## Mixed internal and external services

You can mix internal and external services. For example, to use the bundled
PostgreSQL but an external Redis:

```yaml
postgresql:
  enabled: true
  auth:
    postgresqlPassword: secure-password
    password: secure-password

redis:
  enabled: false

externalRedis:
  host: redis.example.com
  port: 6379
  password: your-redis-password
```

## See also

- {doc}`helm-settings`
- {doc}`/reference/environment-vars`
