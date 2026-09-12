#### Pods termination grace period

During deployment restarts or new rollouts, when old ReplicaSet Pods are being
terminated, the corresponding jobs which are managed (executed or controlled)
by old Ascender Pods may end up in `Error` state as there is no mechanism to
transfer them to the newly spawned Ascender Pods. To work around the problem one
could set `termination_grace_period_seconds` in AWX spec, which does the
following:

* It sets the corresponding
  [`terminationGracePeriodSeconds`](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination)
  Pod spec of the Ascender Deployment to the value provided

  > The grace period is the duration in seconds after the processes running in
  > the pod are sent a termination signal and the time when the processes are
  > forcibly halted with a kill signal

* It adds a
  [`PreStop`](https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/#hook-handler-execution)
  hook script, which will keep Ascender Pods in terminating state until it finished,
  up to `terminationGracePeriodSeconds`.

  > This grace period applies to the total time it takes for both the PreStop
  > hook to execute and for the Container to stop normally

  While the hook script just waits until the corresponding Ascender Pod (instance)
  no longer has any managed jobs, in which case it finishes with success and
  hands over the overall Pod termination process to normal Ascender processes.

One may want to set this value to the maximum duration they accept to wait for
the affected Jobs to finish. Keeping in mind that such finishing jobs may
increase Pods termination time in such situations as `kubectl rollout restart`
or Kubernetes [API-initiated
evictions](https://kubernetes.io/docs/concepts/scheduling-eviction/api-eviction/).

#### Upgrades

`termination_grace_period_seconds` does not cover an upgrade to a new Ascender
version on its own. Once the first Pod running the new version registers itself
as an instance, every control node still running the old version stops its own
services, because Ascender shuts a node down when it sees a peer reporting a higher
version. That happens from inside the container, so it preempts the `PreStop`
hook, and the jobs the hook was waiting for fail with `Task was canceled due to
receiving a shutdown signal.`

Set `upgrade_drain_timeout` to also wait for those jobs *before* the new version
is rolled out. When the application image changes, the operator disables each
control node, so that new jobs stay pending rather than being scheduled onto a
Pod that is about to be replaced, and waits for the jobs already running there
to finish. Once they have, or once the timeout expires, the deployments are
applied as usual. The wait happens before the schema migration runs, so the
draining nodes are never running old code against a migrated database.

A drain that reaches its timeout does not abort the upgrade: it proceeds, and
any jobs still running are failed by the rollout as they would be without this
setting.

| Name                             | Description                                                                                                                                            | Default |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------- |
| termination_grace_period_seconds | Optional duration in seconds pods needs to terminate gracefully                                                                                          | not set |
| upgrade_drain_timeout            | Seconds to wait for the control nodes' running jobs to finish before rolling the deployments to a new application version. 0 does not wait.               | 0       |
