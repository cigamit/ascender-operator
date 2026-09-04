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
helm install my-ascender-operator ascender-operator/ascender-operator -n ascender --create-namespace -f my-values.yml --version 1.3.0
```

To uninstall the chart:

```bash
helm delete my-ascender-operator
```
