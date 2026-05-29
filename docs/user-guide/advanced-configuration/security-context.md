#### Service Account

It is possible to modify some `SecurityContext` proprieties of the various deployments and stateful sets if needed.

| Name                               | Description                                  | Default |
| ---------------------------------- | -------------------------------------------- | ------- |
| security_context_settings          | SecurityContext for Task and Web deployments | {}      |
| postgres_security_context_settings | SecurityContext for Task and Web deployments | {}      |
| restricted_security_context        | Make operator-managed pods Pod Security Admission `restricted` compliant | false   |


Example configuration securityContext for the Task and Web deployments:

```yaml
spec:
  security_context_settings:
    allowPrivilegeEscalation: false
    capabilities:
        drop:
        - ALL
```


```yaml
spec:
  postgres_security_context_settings:
    runAsNonRoot: true
```


#### Restricted Pod Security Admission

Setting `restricted_security_context: true` renders the operator-managed pods (web, task, the migration job, and the managed postgres) to comply with the [Pod Security Admission `restricted`](https://kubernetes.io/docs/concepts/security/pod-security-standards/#restricted) standard: every container sets `allowPrivilegeEscalation: false` and drops all capabilities, and the pods run as non-root with the `RuntimeDefault` seccomp profile. It defaults to `false`, which leaves the generated resources unchanged.

```yaml
spec:
  restricted_security_context: true
```

`task_privileged` and `redis_capabilities` are still honored, and `security_context_settings` is merged last so it overrides these defaults. The managed postgres is made compliant for its default image; for a different image set `runAsUser` via `postgres_security_context_settings`, or use an external database.
