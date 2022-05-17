# Contributing Guide

Brigade Noisy Neighbor is an official extension of the Brigade project and as
such follows all of the practices and policies laid out in the main
[Brigade Contributor Guide](https://docs.brigade.sh/topics/contributor-guide/).
Anyone interested in contributing to this component should familiarize themselves
with that guide _first_.

The remainder of _this_ document only supplements the above with things specific
to this project.

## Running `make hack-kind-up`

As with the main Brigade repository, running `make hack-kind-up` in this
repository will utilize [ctlptl](https://github.com/tilt-dev/ctlptl) and
[KinD](https://kind.sigs.k8s.io/) to launch a local, development-grade
Kubernetes cluster that is also connected to a local Docker registry.

In contrast to the main Brigade repo, this cluster is not pre-configured for
building and running Brigade itself from source, rather it is pre-configured for
building and running _this component_ from source. Because Brigade is a logical
prerequisite for this component to be useful in any way, `make hack-kind-up`
will pre-install a recent, _stable_ release of Brigade into the cluster.

## Running `tilt up`

As with the main Brigade repository, running `tilt up` will build and deploy
project code (the Noisy Neighbor, in this case) from source.

For Noisy Neighbor to successfully communicate with the Brigade instance in your
local, development-grade cluster, you will need to execute the following steps
_before_ running `tilt up`:

1. Log into Brigade:

   ```shell
   $ brig login -k -s https://localhost:31600 --root
   ```

   The root password is `F00Bar!!!`.

1. Create a service account for Noisy Neighbor:

   ```shell
   $ brig service-account create \
       --id noisy-neighbor \
       --description noisy-neighbor
   ```

1. Copy the token returned from the previous step and export it as the
   `BRIGADE_API_TOKEN` environment variable:

   ```shell
   $ export BRIGADE_API_TOKEN=<token from previous step>
   ```

1. Grant the service account permission to create events:

   ```shell
   $ brig role grant EVENT_CREATOR \
     --service-account noisy-neighbor \
     --source brigade.sh/noisy-neighbor
   ```

You can then run `tilt up` to build and deploy this component from source.

> ⚠️&nbsp;&nbsp;Contributions that automate the creation and configuration of
> the service account setup are welcome.

## Subscribing to Noise Events

Proceed with creating one or more projects that subscribe to noise events by
following the instructions from
[`README.md`](README.md).
