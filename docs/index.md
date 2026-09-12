
The Ascender Operator provides a Kubernetes-native installation method for [Ascender](https://github.com/ctrliq/ascender), through a Custom Resource Definition (CRD) that describes a deployment and a controller that reconciles the cluster against it.

These pages were forked from the AWX Operator documentation. The prose is Ascender's now, but the API is not renamed: the custom resources are still `AWX`, `AWXBackup`, `AWXRestore` and `AWXMeshIngress` in the `awx.ansible.com` group, so every manifest, field and command below keeps its original names.
