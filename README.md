# ascender-operator Helm charts

## Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

```bash
helm repo add ascender-operator https://ctrliq.github.io/ascender-operator/
```

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
ascender-operator` to see the charts.

To install the `ascender-operator` chart:

```bash
helm install my-ascender-operator ascender-operator/ascender-operator
```

To install a specific ascender-operator helm chart version in a specific namespace:

```
helm install my-ascender-operator ascender-operator/ascender-operator -n ascender --create-namespace -f my-values.yml --version 25.6.1
```

To uninstall the chart:

```bash
helm delete my-ascender-operator
```

Example `my-values.yml` (tested in K3S)

```
AWX:
  enabled: true
  name: ascender
  spec:
    ingress_type: ingress
    ingress_class_name: traefik
    hostname: ascender.example.com
    extra_settings:
      - setting: CSRF_TRUSTED_ORIGINS
        value:
          - https://ascender.example.com
          - http://ascender.example.com

    secret_key_secret: ascender-secret-key

    projects_persistence: true
    projects_storage_class: local-path
    projects_storage_size: 8Gi
    projects_storage_access_mode: ReadWriteOnce
```
