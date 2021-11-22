# Zulip

[Zulip](https://zulipchat.com/), the world's most productive chat

Helm chart based on https://github.com/zulip/docker-zulip

## Installation

Copy `values-local.yaml.example`, modify it as instructed in the comments , then
install with 

```
helm install -f ./values-local.yaml zulip .
```

After installation you will need to get a realm creation link, the `notes` will
tell you how can you get it!
