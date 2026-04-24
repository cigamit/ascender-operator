## Resource Cleanup

### Deployment Revision History

Kubernetes retains old ReplicaSets from Deployments to allow rollbacks. By default, Ascender limits this to **2** old ReplicaSets per Deployment (web, task, mesh ingress, and controller-manager). You can adjust this with `revision_history_limit`.

| Name                   | Description                                                               | Default |
| ---------------------- | ------------------------------------------------------------------------- | ------- |
| revision_history_limit | Number of old ReplicaSets to retain for rollback across all Deployments   | 2       |

Example configuration:

```yaml
spec:
  revision_history_limit: 5
```

Setting this to `0` will cause Kubernetes to garbage-collect all old ReplicaSets immediately, which prevents rollbacks but keeps the cluster tidy.
