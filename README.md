# docker-zulip
Zulip Server as a Docker Image

#### Please, don't use the master branch (I'm not really testing when commiting to master!!), use a version branch if available!!

*Quay.io* https://quay.io/repository/galexrt/zulip
*Docker Hub* https://hub.docker.com/r/galexrt/zulip
___

##### WARNING! This is currently work in progress. It's not fully "working" yet.


In the folder [includes/zulip](includes/zulip) are modified zulip manifestss for puppet.
The manifests are modified to "just" install zulip (+ rabbitmq-server, because of zulip not allowing configuration of an external rabbitmq-server) not more, not less.

> Powerful open source group chat - From zulip.org

See https://zulip.org/ for details about the Zulip Server
