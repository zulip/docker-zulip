## [0.11.43] - 2025-12-02

- Allow setting extraObjects, e.g. for SecretProviderClass or ConfigMap.
- Allow setting an explicit ingress.className

## [0.11.42] - 2025-11-13

- Switch to bitnamilegacy images.
- Fix containerSecurityContext to run PostgreSQL as non-root.
- Switch to healthchecking the /health endpoint, and add ACL'ing so Zulip allows
  those checks.
- Reformat CHART.yaml with Prettier

## [0.11.41] - 2025-10-30

- Add maintainer information
- Repackage with additional version space

## [0.11.4] - 2025-10-23

- Update to Zulip Server 11.4

## [0.11.3] - 2025-10-22

- Update to Zulip Server 11.3
- Support valueFrom in both `SECRETS_` and `SETTING_` values
- Support `PROXY_ALLOW_*` settings for outgoing proxy rules
- Support `DB_NAME` / `DB_USER` settings.

## [0.11.2] - 2025-09-16

- Update to Zulip Server 11.2

## [0.11.1] - 2025-09-11

- Update to Zulip Server 11.1

## [0.11.0] - 2025-08-13

- Update to Zulip Server 11.0

## [0.10.4] - 2025-07-02

- Update to Zulip Server 10.4

## [0.10.3] - 2025-05-15

- Update to Zulip Server 10.3

## [0.10.2] - 2025-04-15

- Update to Zulip Server 10.2

## [0.10.1] - 2025-03-28

- Update to Zulip Server 10.1

## [0.10.0] - 2025-03-20

- Update to Zulip Server 10.0

## [0.9.40] - 2025-01-16

- Update to Zulip Server 9.4

## [0.9.30] - 2024-11-23

- Update to Zulip Server 9.3

## [0.9.20] - 2024-09-16

- Update to Zulip Server 9.2
- Change nginx's max-upload size to match standard Zulip (80m)

## [0.9.13] - 2024-09-09

- More thoroughly remove the `ubuntu` user

## [0.9.12] - 2024-09-09

- Fix consistent user-ID for `zulip` user

## [0.9.11] - 2024-08-28

- Packaging updates for Docker

## [0.9.1] - 2024-08-02

- Update Zulip Server to 9.1

## [0.9.1] - 2024-07-25

- Update Zulip Server to 9.1

## [0.8.4] - 2024-05-09

- Update Zulip Server to 8.4

## [0.8.3] - 2024-03-19

- Update Zulip Server to 8.3

## [0.8.2] - 2024-02-16

- Update Zulip Server to 8.2

## [0.8.1] - 2024-01-24

- Update Zulip Server to 8.1

## [0.8.0] - 2023-12-15

- Update Zulip Server to 8.0

## [0.7.5] - 2023-11-17

- Update Zulip Server to 7.5

## [0.7.4] - 2023-09-15

- Update Zulip Server to 7.4

## [0.7.3] - 2023-08-25

- Update Zulip Server to 7.3

## [0.7.2] - 2023-07-05

- Update Zulip Server to 7.2

## [0.7.1] - 2023-06-13

- Update Zulip Server to 7.1

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
