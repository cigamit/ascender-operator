## Resource Cleanup

### Deployment Revision History

Kubernetes retains old ReplicaSets from Deployments to allow rollbacks. By default, Ascender limits this to **2** old ReplicaSets per Deployment (web, task, mesh ingress, and controller-manager). You can adjust this with `revision_history_limit` for all except the controller-manager (its hard coded).

| Name                   | Description                                                               | Default |
| ---------------------- | ------------------------------------------------------------------------- | ------- |
| revision_history_limit | Number of old ReplicaSets to retain for rollback across all Deployments   | 2       |

Example configuration:

```yaml
spec:
  revision_history_limit: 5
```

Setting this to `0` will cause Kubernetes to garbage-collect all old ReplicaSets immediately, which prevents rollbacks but keeps the cluster tidy.

### Migration Job Cleanup

Kubernetes can automatically delete finished migration Jobs after a configurable period via `ttlSecondsAfterFinished`. By default, Ascender sets this to **86400 seconds (1 day)**. You can adjust this with `migration_job_ttl`.

| Name              | Description                                                            | Default |
| ----------------- | ---------------------------------------------------------------------- | ------- |
| migration_job_ttl | Seconds after which finished migration Jobs are automatically deleted  | 86400   |

Example configuration:

```yaml
spec:
  migration_job_ttl: 3600  # delete after 1 hour
```

Setting this to `0` will delete the Job immediately after it finishes.
