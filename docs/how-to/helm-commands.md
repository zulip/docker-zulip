# Helm: Running commands

Once the Zulip pod is running, you can interact with it using `kubectl exec`.

## Getting a shell

```bash
kubectl exec zulip-0 -c zulip -- bash
```

## Running management commands

Some parts of the Zulip documentation may reference running {doc}`management
commands <zulip:production/management-commands>`. These must be run as the
`zulip` user:

```bash
kubectl exec zulip-0 -c zulip -- \
    runuser -u zulip -- \
    /home/zulip/deployments/current/manage.py list_realms
```

## Viewing logs

```bash
# Stream the main container logs
kubectl logs zulip-0 -c zulip -f

# View Zulip's error log
kubectl exec zulip-0 -c zulip -- \
    cat /var/log/zulip/errors.log
```

## Checking pod health

```bash
kubectl get pods -l app.kubernetes.io/name=zulip
kubectl describe pod -l app.kubernetes.io/name=zulip
```

## Restarting the deployment

```bash
kubectl rollout restart statefulset/zulip
kubectl rollout status statefulset/zulip
```

## Port-forwarding for local access

To access Zulip from your local machine without an Ingress:

```bash
kubectl port-forward svc/zulip 8080:80
```

Then visit `http://localhost:8080` in your browser.

## See also

- [`kubectl exec` reference](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_exec/)
- {doc}`zulip:production/management-commands`
