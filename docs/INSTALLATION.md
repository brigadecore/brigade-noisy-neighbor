# Installation

## Prerequisites

* A Kubernetes cluster:
  * For which you have the `admin` cluster role.
  * That is already running Brigade v2.0.0 or greater.
* `helm`: Commands below require `helm` 3.7.0+.
* `brig`: The Brigade CLI. Commands below require `brig` 2.0.0+.

## Create a Service Account for the Noisy Neighbor

> ⚠️&nbsp;&nbsp;To proceed beyond this point, you'll need to be logged into
> Brigade as the "root" user (not recommended) or (preferably) as a user with
> the `ADMIN` role. Further discussion of this is beyond the scope of this
> documentation. Please refer to Brigade's own documentation.

1. Using the `brig` CLI, create a service account for the Noisy Neighbor to use:

   ```shell
   $ brig service-account create \
       --id brigade-noisy-neighbor \
       --description "Used by Brigade Noisy Neighbor"
   ```

1. Make note of the __token__ returned. This value will be used in another step.

   > ⚠️&nbsp;&nbsp;This is your only opportunity to access this value, as
   > Brigade does not save it.

1. Authorize this service account to create events:

   ```shell
   $ brig role grant EVENT_CREATOR
       --service-account brigade-noisy-neighbor \
       --source brigade.sh/noisy-neighbor
   ```

   > ⚠️&nbsp;&nbsp;The `--source brigade.sh/noisy-neighbor` option specifies
   > that this service account can be used _only_ to create events having a
   > value of `brigade.sh/noisy-neighbor` in the event's `source` field. This is
   > a security measure that prevents this component from using this token for
   > impersonating other event sources.

## Install the Noisy Neighbor

> ⚠️&nbsp;&nbsp;be sure you are using
> [Helm 3.7.0](https://github.com/helm/helm/releases/tag/v3.7.0) or greater and
> enable experimental OCI support:
>
> ```shell
>  $ export HELM_EXPERIMENTAL_OCI=1
>  ```

1. As this component requires some specific configuration to function properly,
   we'll first create a values file containing those settings. Use the following
   command to extract the full set of configuration options into a file you can
   modify:

   ```shell
   $ helm inspect values oci://ghcr.io/brigadecore/brigade-noisy-neighbor \
       --version v0.4.1 > ~/brigade-noisy-neighbor-values.yaml
   ```

1. Edit `~/brigade-noisy-neighbor-values.yaml`, making the following changes:

   * `brigade.apiAddress`: Set this to the address of the Brigade API server,
     beginning with `https://`.

   * `brigade.apiToken`: Set this to the service account token obtained when you
     created the Brigade service account for this component.

   * `noiseFrequency`: Optionally edit this to control the frequency with which
     noise events are emitted into Brigade's event bus.

1. Save your changes to `~/brigade-noisy-neighbor-values.yaml`.

1. Use the following command to install the Noisy Neighbor:

   ```shell
   $ helm install brigade-noisy-neighbor \
       oci://ghcr.io/brigadecore/brigade-noisy-neighbor \
       --version v0.4.1 \
       --create-namespace \
       --namespace brigade-noisy-neighbor \
       --values ~/brigade-noisy-neighbor-values.yaml \
       --wait
   ```
