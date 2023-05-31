## [0.7.0] - 2023-05-31

- Update Zulip Server to 7.0

## [0.6.2] - 2023-05-19

- Update Zulip Server to 6.2

## [0.6.1] - 2023-01-23

- Update Zulip Server to 6.1

## [0.6.0] - 2022-11-23

- Update Zulip Server to 6.0

## [0.5.0] - 2022-11-16

- Update Zulip Server to 5.7

## [0.4.0] - 2022-06-21

- Update Zulip Server 5.2 to 5.6

## [0.3.0] - 2022-04-21

- Update dependencies:

  - Helm charts:

    | Repository                         | Name       | Version |
    | ---------------------------------- | ---------- | ------- |
    | https://charts.bitnami.com/bitnami | memcached  | 6.0.16  |
    | https://charts.bitnami.com/bitnami | postgresql | 11.1.22 |
    | https://charts.bitnami.com/bitnami | rabbitmq   | 8.32.0  |
    | https://charts.bitnami.com/bitnami | redis      | 16.8.7  |

  - Update postgres 10 to postgres 14
  - Update Zulip 4.7 to 5.2

- Remove autoscaling code
- Remove readiness probe because its function is the same as the liveness probe

## [0.2.0] - 2021-11-22

- Use dependency charts from the Bitnami repository for Memcached, Rabbitmq,
  Redis and PostgreSQL
- Use a StatefulSet instead of a Deployment
- Add the possibility to run postSetup scripts

## [0.1.0] - 2020-12-30

- First version of helm chart created
