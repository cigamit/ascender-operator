### Database Configuration

#### PostgreSQL Version

The default PostgreSQL version for the managed database deployed by the latest version of the awx-operator is PostgreSQL 18, using the `quay.io/sclorg/postgresql-18-c9s` image. You can find this default for a given version at the default value for [supported_pg_version](https://github.com/ctrliq/ascender-operator/blob/devel/roles/installer/vars/main.yml).

We only have coverage for the default version of PostgreSQL. Newer versions of PostgreSQL will likely work, but should only be configured as an external database. If your database is managed by the awx-operator (default if you don't specify a `postgres_configuration_secret`), then you should not override the default version as this may cause issues when awx-operator tries to upgrade your postgresql pod.

#### External PostgreSQL Service

To configure AWX to use an external database, the Custom Resource needs to know about the connection details. To do this, create a k8s secret with those connection details and specify the name of the secret as `postgres_configuration_secret` at the CR spec level.


The secret should be formatted as follows:

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: <resourcename>-postgres-configuration
  namespace: <target namespace>
stringData:
  host: <external ip or url resolvable by the cluster>
  port: <external port, this usually defaults to 5432>
  database: <desired database name>
  username: <username to connect as>
  password: <password to connect with>
  sslmode: prefer
  target_session_attrs: read-write
  type: unmanaged
type: Opaque
```

> Please ensure that the value for the variable `password` should _not_ contain single or double quotes (`'`, `"`) or backslashes (`\`) to avoid any issues during deployment, [backup](https://github.com/ansible/awx-operator/tree/devel/roles/backup) or [restoration](https://github.com/ansible/awx-operator/tree/devel/roles/restore).

> It is possible to set a specific username, password, port, or database, but still have the database managed by the operator. In this case, when creating the postgres-configuration secret, the `type: managed` field should be added.

**Note**: The variable `sslmode` is valid for `external` databases only. The allowed values are: `prefer`, `disable`, `allow`, `require`, `verify-ca`, `verify-full`.

**Note**: The variable `target_session_attrs` is only useful for `clustered external` databases. The allowed values are: `any` (default), `read-write`, `read-only`, `primary`, `standby` and `prefer-standby`, whereby only `read-write` and `primary` really make sense in AWX use, as you want to connect to a database node that offers write support.

Once the secret is created, you can specify it on your spec:

```yaml
---
spec:
  ...
  postgres_configuration_secret: <name-of-your-secret>
```

#### Migrating data from an old AWX instance

For instructions on how to migrate from an older version of AWX, see [migration.md](../migration/migration.md).

#### Managed PostgreSQL Service

If you don't have access to an external PostgreSQL service, the AWX operator can deploy one for you along side the AWX instance itself.

The following variables are customizable for the managed PostgreSQL service

| Name                                          | Description                                                     | Default                                 |
| --------------------------------------------- | --------------------------------------------------------------- | --------------------------------------- |
| postgres_image                                | Path of the image to pull                                       | quay.io/sclorg/postgresql-18-c9s        |
| postgres_image_version                        | Image version to pull                                           | latest                                  |
| postgres_resource_requirements                | PostgreSQL container (and initContainer) resource requirements  | requests: {cpu: 10m, memory: 64Mi}      |
| postgres_storage_requirements                 | PostgreSQL container storage requirements                       | requests: {storage: 8Gi}                |
| postgres_storage_class                        | PostgreSQL PV storage class                                     | Empty string                            |
| postgres_priority_class                       | Priority class used for PostgreSQL pod                          | Empty string                            |
| postgres_extra_settings                       | PostgreSQL configuration settings to be added to postgresql.conf | `[]`                                    |

Example of customization could be:

```yaml
---
spec:
  ...
  postgres_resource_requirements:
    requests:
      cpu: 500m
      memory: 2Gi
    limits:
      cpu: '1'
      memory: 4Gi
  postgres_storage_requirements:
    requests:
      storage: 8Gi
    limits:
      storage: 50Gi
  postgres_storage_class: fast-ssd
  postgres_extra_settings:
    - setting: max_connections
      value: "1000"
```

**Note**: If `postgres_storage_class` is not defined, PostgreSQL will store it's data on a volume using the default storage class for your cluster.

## PostgreSQL Extra Settings

!!! warning "Deprecation Notice"
    The `postgres_extra_args` parameter is **deprecated** and should no longer be used. Use `postgres_extra_settings` instead for configuring PostgreSQL parameters. The `postgres_extra_args` parameter will be removed in a future version of the AWX operator.

You can customize PostgreSQL configuration by adding settings to the `postgresql.conf` file using the `postgres_extra_settings` parameter. This allows you to tune PostgreSQL performance, security, and behavior according to your specific requirements.

The `postgres_extra_settings` parameter accepts an array of setting objects, where each object contains a `setting` name and its corresponding `value`,
both of which are strings. It only applies to the managed PostgreSQL instance; it is ignored when an external database is configured.

!!! note
    The `postgres_extra_settings` parameter replaces the deprecated `postgres_extra_args` parameter and provides a more structured way to configure PostgreSQL settings.

### Configuration Format

```yaml
spec:
  postgres_extra_settings:
    - setting: max_connections
      value: "499"
    - setting: ssl_ciphers
      value: "HIGH:!aNULL:!MD5"
```

**Common PostgreSQL settings you might want to configure:**

| Setting | Description | Example Value |
|---------|-------------|---------------|
| `max_connections` | Maximum number of concurrent connections | `"200"` |
| `ssl_ciphers` | SSL cipher suites to use | `"HIGH:!aNULL:!MD5"` |
| `shared_buffers` | Amount of memory for shared memory buffers | `"256MB"` |
| `effective_cache_size` | Planner's assumption about effective cache size | `"1GB"` |
| `work_mem` | Amount of memory for internal sort operations | `"4MB"` |
| `maintenance_work_mem` | Memory for maintenance operations | `"64MB"` |
| `checkpoint_completion_target` | Target for checkpoint completion | `"0.9"` |
| `wal_buffers` | Amount of memory for WAL buffers | `"16MB"` |

### Settings introduced in PostgreSQL 16, 17 and 18

The managed database runs PostgreSQL 18. The settings below were added or changed in PostgreSQL 16 through 18 and are the ones most relevant to AWX workloads (large `IN (...)` lists from the ORM, high-volume job event inserts, and tables that churn in place). All of them are configured through `postgres_extra_settings`; the operator does not set any of them by default.

| Setting | Added in | Description | Example Value |
|---------|----------|-------------|---------------|
| `io_method` | 18 | Asynchronous I/O implementation: `worker` (default) or `sync`. Do not set `io_uring`, see the warning below. | `"worker"` |
| `io_workers` | 18 | Number of I/O worker processes when `io_method` is `worker` (default 3). Raise on larger database nodes. | `"6"` |
| `effective_io_concurrency` | older, default raised in 18 | Concurrent storage I/O operations a session may issue (default now 16). Increase on fast SSD or NVMe backed volumes. | `"32"` |
| `maintenance_io_concurrency` | older, default raised in 18 | Same as above for maintenance work such as `VACUUM` (default now 16). | `"32"` |
| `transaction_timeout` | 17 | Terminates any session whose transaction runs longer than this, closing the gap left by `statement_timeout` and `idle_in_transaction_session_timeout`. Set it well above your longest migration or backup. | `"1h"` |
| `vacuum_buffer_usage_limit` | 16 | Size of the buffer ring used by `VACUUM` and `ANALYZE` (default 2MB). Larger values speed up vacuum of big tables. | `"64MB"` |
| `autovacuum_worker_slots` | 18 | Upper bound for `autovacuum_max_workers`, which can now be raised at runtime without a restart. | `"16"` |
| `autovacuum_vacuum_max_threshold` | 18 | Caps the number of dead tuples needed to trigger autovacuum on very large tables (default 100,000,000). | `"10000000"` |
| `scram_iterations` | 16 | Iteration count for SCRAM-SHA-256 password hashing (default 4096). | `"8192"` |
| `reserved_connections` | 16 | Connection slots reserved for roles granted `pg_use_reserved_connections`, in addition to the superuser reservation. | `"3"` |
| `summarize_wal` | 17 | Enables WAL summarization, required for incremental `pg_basebackup`. | `"on"` |
| `track_io_timing` | older | Collects I/O timing for the per-backend-type `pg_stat_io` view added in 16. | `"on"` |
| `track_cost_delay_timing` | 18 | Records time spent in vacuum cost delays, visible in `pg_stat_progress_vacuum`. | `"on"` |

!!! warning "Do not set `io_method` to `io_uring`"
    PostgreSQL 18 refuses to start when `io_method = io_uring` and io_uring is unavailable; there is no fallback to another method. io_uring is commonly unavailable on Kubernetes nodes: RHEL and Rocky Linux 9 kernels disable it kernel-wide, and the default container runtime seccomp profiles block the io_uring syscalls (the operator applies the runtime default seccomp profile when `restricted_security_context` is enabled). Keep the default `io_method = worker`, which captures most of the asynchronous I/O benefit.

!!! note
    `io_method`, `autovacuum_worker_slots`, `reserved_connections` and `scram_iterations` can only change at server start. The operator restarts the PostgreSQL pod whenever `postgres_extra_settings` changes, so this happens automatically.

### Important Notes

!!! warning
    - Changes to `postgres_extra_settings` require a PostgreSQL pod restart to take effect.
    - Some settings may require specific PostgreSQL versions or additional configuration.
    - Always test configuration changes in a non-production environment first.

!!! tip
    - Every `value` must be a string, so quote it in the YAML configuration.
    - Numeric values are strings too (`"200"`, not `200`); an unquoted number is rejected by the CRD schema.
    - Boolean values should be provided as strings ("on"/"off" or "true"/"false").

For a complete list of available PostgreSQL configuration parameters, refer to the [PostgreSQL documentation](https://www.postgresql.org/docs/current/runtime-config.html).

**Verification:**

You can verify that your settings have been applied by connecting to the PostgreSQL database and running:

```bash
kubectl exec -it <postgres-pod-name> -n <namespace> -- psql
```

Then run the following query:

```sql
SELECT name, setting FROM pg_settings;
```

#### Note about overriding the postgres image

We recommend you use the default sclorg image. The operator automatically migrates a managed database that is still running an older major version (the dockerhub `postgres:13` image, `postgresql-13-c9s` or `postgresql-15-c9s`) to `postgresql-18-c9s` the next time it reconciles the deployment. See [PostgreSQL Upgrade Considerations](../upgrade/upgrading.md#postgresql-upgrade-considerations) for what happens during that migration.

You can no longer configure a custom `postgres_data_path` because it is hardcoded in the quay.io/sclorg/postgresql-18-c9s image.

The CentOS Stream 10 based `quay.io/sclorg/postgresql-18-c10s` image is built from the same container scripts and uses the same data directory and environment variables, so it can be selected with `postgres_image` if you prefer it.

If you override the postgres image to use a custom postgres image like postgres:18 for example, the default data directory path may be different. These images cannot be used interchangeably.

#### Initialize Postgres data volume

When using a hostPath backed PVC and some other storage classes like longhorn storagfe, the postgres data directory needs to be accessible by the user in the postgres pod (UID 26).

To initialize this directory with the correct permissions, configure the following setting, which will use an init container to set the permissions in the postgres volume.

```yaml
spec:
  postgres_data_volume_init: true
```

Should you need to modify the init container commands, there is an example below.

```yaml
postgres_init_container_commands: |
  chown 26:0 /var/lib/pgsql/data
  chmod 700 /var/lib/pgsql/data
```
