### Basic Install

After cloning this repository, you must choose the tag to run:
```sh
git clone git@github.com:ctrliq/ascender-operator.git
cd ascender-operator
git tag
git checkout tags/<tag>

# For instance:
git checkout tags/2.19.6
```

If you work from a fork and made modifications since the tag was issued, you must provide the VERSION number to deploy. Otherwise the operator will get stuck in "ImagePullBackOff" state:

```sh
export VERSION=<tag>

# For instance:
export VERSION=2.19.6
```

Once you have a running Kubernetes cluster, you can deploy Ascender Operator into your cluster using [Kustomize](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/). Since kubectl version 1.14 kustomize functionality is built-in (otherwise, follow the instructions here to install the latest version of Kustomize: https://kubectl.docs.kubernetes.io/installation/kustomize/ )

> Some things may need to be configured slightly differently for different Kubernetes flavors for the networking aspects. When installing on Kind, see the [kind install docs](./kind-install.md) for more details.

There is a make target you can run:
```
make deploy
```

If you have a custom operator image you have built, you can specify it with:
```
IMG=quay.io/$YOURNAMESPACE/ascender-operator:$YOURTAG make deploy
```

Otherwise, you can manually create a file called `kustomization.yaml` with the following content:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  # Find the latest tag here: https://github.com/ctrliq/ascender-operator/releases
  - github.com/ctrliq/ascender-operator/config/default?ref=<tag>

# Set the image tags to match the git version from above
images:
  - name: ghcr.io/ctrliq/ascender-operator
    newTag: <tag>

# Specify a custom namespace in which to install Ascender
namespace: ascender
```

> **TIP:** If you need to change any of the default settings for the operator (such as resources.limits), you can add [patches](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/patches/) at the bottom of your kustomization.yaml file.

Install the manifests by running this:

```
$ kubectl apply -k .
namespace/ascender created
customresourcedefinition.apiextensions.k8s.io/awxbackups.awx.ansible.com created
customresourcedefinition.apiextensions.k8s.io/awxrestores.awx.ansible.com created
customresourcedefinition.apiextensions.k8s.io/awxs.awx.ansible.com created
serviceaccount/ascender-operator-controller-manager created
role.rbac.authorization.k8s.io/ascender-operator-ascender-manager-role created
role.rbac.authorization.k8s.io/ascender-operator-leader-election-role created
clusterrole.rbac.authorization.k8s.io/ascender-operator-metrics-reader created
clusterrole.rbac.authorization.k8s.io/ascender-operator-proxy-role created
rolebinding.rbac.authorization.k8s.io/ascender-operator-ascender-manager-rolebinding created
rolebinding.rbac.authorization.k8s.io/ascender-operator-leader-election-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/ascender-operator-proxy-rolebinding created
configmap/ascender-operator-ascender-manager-config created
service/ascender-operator-controller-manager-metrics-service created
deployment.apps/ascender-operator-controller-manager created
```

Wait a bit and you should have the `ascender-operator` running:

```
$ kubectl get pods -n ascender
NAME                                               READY   STATUS    RESTARTS   AGE
ascender-operator-controller-manager-66ccd8f997-rhd4z   2/2     Running   0          11s
```

So we don't have to keep repeating `-n ascender`, let's set the current namespace for `kubectl`:

```
$ kubectl config set-context --current --namespace=ascender
```

Next, create a file named `ascender-demo.yml` in the same folder with the suggested content below. The `metadata.name` you provide will be the name of the resulting Ascender deployment.

**Note:** If you deploy more than one Ascender instance to the same namespace, be sure to use unique names.

```yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: ascender-demo
spec:
  service_type: nodeport
```

> It may make sense to create and specify your own secret key for your deployment so that if the k8s secret gets deleted, it can be re-created if needed.  If it is not provided, one will be auto-generated, but cannot be recovered if lost. Read more [here](../user-guide/admin-user-account-configuration.md#secret-key-configuration).

If you are on Openshift, you can take advantage of Routes by specifying the following your spec. This will automatically create a Route for you with a custom hostname. This can be found on the Route section of the Openshift Console.

```yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: ascender-demo
spec:
  service_type: clusterip
  ingress_type: Route
```


Make sure to add this new file to the list of "resources" in your `kustomization.yaml` file:

```yaml
...
resources:
  - github.com/ctrliq/ascender-operator/config/default?ref=<tag>
  # Add this extra line:
  - ascender-demo.yml
...
```

Finally, apply the changes to create the Ascender instance in your cluster:

```
kubectl apply -k .
```

After a few minutes, the new Ascender instance will be deployed. You can look at the operator pod logs in order to know where the installation process is at:

```
$ kubectl logs -f deployments/ascender-operator-controller-manager -c ascender-manager
```

After a few seconds, you should see the operator begin to create new resources:

```
$ kubectl get pods -l "app.kubernetes.io/managed-by=ascender-operator"
NAME                        READY   STATUS    RESTARTS   AGE
ascender-demo-77d96f88d5-pnhr8   4/4     Running   0          3m24s
ascender-demo-postgres-0         1/1     Running   0          3m34s

$ kubectl get svc -l "app.kubernetes.io/managed-by=ascender-operator"
NAME                TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
ascender-demo-postgres   ClusterIP   None           <none>        5432/TCP       4m4s
ascender-demo-service    NodePort    10.109.40.38   <none>        80:31006/TCP   3m56s
```

Once deployed, the Ascender instance will be accessible by running:

```
$ minikube service -n ascender ascender-demo-service --url
```

By default, the admin user is `admin` and the password is available in the `<resourcename>-admin-password` secret. To retrieve the admin password, run:

```
$ kubectl get secret ascender-demo-admin-password -o jsonpath="{.data.password}" | base64 --decode ; echo
yDL2Cx5Za94g9MvBP6B73nzVLlmfgPjR
```

You just completed the most basic install of an Ascender instance via this operator. Congratulations!!!

For an example using the Nginx Ingress Controller in Minikube, don't miss our [demo video](https://asciinema.org/a/416946).
