#### Assigning Ascender pods to specific nodes

You can constrain the Ascender pods created by the operator to run on a certain subset of nodes. `node_selector` and `postgres_selector` constrains
the Ascender pods to run only on the nodes that match all the specified key/value pairs. `tolerations` and `postgres_tolerations` allow the Ascender
pods to be scheduled onto nodes with matching taints.
The ability to specify topologySpreadConstraints is also allowed through `topology_spread_constraints`
If you want to use affinity rules for your Ascender pod you can use the `affinity` option.

If you want to constrain the web and task pods individually, you can do so by specificying the deployment type before the specific setting. For
example, specifying `task_tolerations` will allow the Ascender task pod to be scheduled onto nodes with matching taints. 

| Name                             | Description                              | Default                          |
| -------------------------------- | ---------------------------------------- | -------------------------------- |
| postgres_image                   | Path of the image to pull                | quay.io/sclorg/postgresql-15-c9s |
| postgres_image_version           | Image version to pull                    | latest                           |
| node_selector                    | Ascender pods' nodeSelector                   | ''                               |
| web_node_selector                | Ascender web pods' nodeSelector               | ''                               |
| task_node_selector               | Ascender task pods' nodeSelector              | ''                               |
| topology_spread_constraints      | Ascender pods' topologySpreadConstraints      | ''                               |
| web_topology_spread_constraints  | Ascender web pods' topologySpreadConstraints  | ''                               |
| task_topology_spread_constraints | Ascender task pods' topologySpreadConstraints | ''                               |
| affinity                         | Ascender pods' affinity rules                 | ''                               |
| web_affinity                     | Ascender web pods' affinity rules             | ''                               |
| task_affinity                    | Ascender task pods' affinity rules            | ''                               |
| tolerations                      | Ascender pods' tolerations                    | ''                               |
| web_tolerations                  | Ascender web pods' tolerations                | ''                               |
| task_tolerations                 | Ascender task pods' tolerations               | ''                               |
| annotations                      | Ascender pods' annotations                    | ''                               |
| postgres_selector                | Postgres pods' nodeSelector              | ''                               |
| postgres_tolerations             | Postgres pods' tolerations               | ''                               |

Example of customization could be:

```yaml
---
spec:
  ...
  node_selector: |
    disktype: ssd
    kubernetes.io/arch: amd64
    kubernetes.io/os: linux
  topology_spread_constraints: |
    - maxSkew: 100
      topologyKey: "topology.kubernetes.io/zone"
      whenUnsatisfiable: "ScheduleAnyway"
      labelSelector:
        matchLabels:
          app.kubernetes.io/name: "<resourcename>"
  tolerations: |
    - key: "dedicated"
      operator: "Equal"
      value: "AWX"
      effect: "NoSchedule"
  task_tolerations: |
    - key: "dedicated"
      operator: "Equal"
      value: "AWX_task"
      effect: "NoSchedule"
  postgres_selector: |
    disktype: ssd
    kubernetes.io/arch: amd64
    kubernetes.io/os: linux
  postgres_tolerations: |
    - key: "dedicated"
      operator: "Equal"
      value: "AWX"
      effect: "NoSchedule"
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: another-node-label-key
            operator: In
            values:
            - another-node-label-value
            - another-node-label-value
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: security
              operator: In
              values:
              - S2
          topologyKey: topology.kubernetes.io/zone
```

#### Special Note on DB-Migration Job Scheduling

For the **db-migration job**, which applies database migrations at cluster startup, you can specify scheduling settings using the `task_*` configurations such as `task_node_selector`, `task_tolerations`, etc.  
If these task-specific settings are not defined, the job will automatically use the global Ascender configurations like `node_selector` and `tolerations`.
