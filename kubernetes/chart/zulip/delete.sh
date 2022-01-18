#! /usr/bin/env bash

helm delete zulip
kubectl delete pvc data-zulip-postgresql-0 redis-data-zulip-redis-master-0
