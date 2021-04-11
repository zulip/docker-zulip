# Zulip

[Zulip](https://zulipchat.com/), the world's most productive chat

Helm chart based on https://github.com/zulip/docker-zulip

## Installation

Grab a copy of values.yaml, modify it as necessary, then install with 
```
helm repo add zulip 'https://raw.githubusercontent.com/zulip/docker-zulip/helm/'
helm upgrade --install --namespace="zulip" --create-namespace -f=./values.yaml zulip zulip/zulip
```

After installation you will need to get a realm creation link, the `notes` will tell you how can you get it!

