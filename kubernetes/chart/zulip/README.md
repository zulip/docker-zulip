# Zulip

[Zulip](https://zulipchat.com/), the world's most productive chat

Helm chart based on https://github.com/zulip/docker-zulip

## Installation

Grab a copy of values.yaml, modify it as necessary, then install with 

```
helm install -f ./values.yaml zulip .
```

After installation you will need to get a realm creation link, the `notes` will
tell you how can you get it!
