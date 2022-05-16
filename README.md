# Brigade Noisy Neighbor

![build](https://badgr.brigade2.io/v1/github/checks/brigadecore/brigade-noisy-neighbor/badge.svg?appID=99005)
[![codecov](https://codecov.io/gh/brigadecore/brigade-noisy-neighbor/branch/main/graph/badge.svg?token=H4P57ZBUCY)](https://codecov.io/gh/brigadecore/brigade-noisy-neighbor)
[![Go Report Card](https://goreportcard.com/badge/github.com/brigadecore/brigade-noisy-neighbor)](https://goreportcard.com/report/github.com/brigadecore/brigade-noisy-neighbor)
[![slack](https://img.shields.io/badge/slack-brigade-brightgreen.svg?logo=slack)](https://kubernetes.slack.com/messages/C87MF1RFD)

<img width="100" align="left" src="logo.png">

The Brigade Noisy Neighbor component emits events (noise) into a Brigade 2
installation's event bus at a configurable frequency. This is useful for
applying load to a Brigade 2 installation for testing purposes or to gain
operational insight.

<br clear="left"/>

After [installation](docs/INSTALLATION.md), subscribe any number of Brigade
[projects](https://docs.brigade.sh/topics/project-developers/projects/)
to events emitted by this component -- all of which have a value of
`brigade.sh/noisy-neighbor` in their `source` field and a value of `noise` in
their `type` field. In the example project definition below, we subscribe to all
such events:

```yaml
apiVersion: brigade.sh/v2
kind: Project
metadata:
  id: noisy-ned
description: Noisy Ned subscribes to events from the Brigade Noisy Neighbor!
spec:
  eventSubscriptions:
  - source: brigade.sh/noisy-neighbor
    types:
    - noise
  workerTemplate:
    defaultConfigFiles:
      brigade.js: | 
        const { events, Job } = require("@brigadecore/brigadier");

        events.on("brigade.sh/noisy-neighbor", "noise", async event => {
          let job = new Job("sleep", "debian:latest", event);
          job.primaryContainer.command = ["sleep"];
          job.primaryContainer.arguments = ["5"];
          await job.run();
        });

        events.process();

```

Assuming this file were named `project.yaml`, you can create the project like
so:

```shell
$ brig project create --file project.yaml
```

> ⚠️&nbsp;&nbsp;Projects always receive discrete copies of each event they are
> subscribed to, so be mindful that no matter the frequency on which the Noisy
> Neighbor is configured to emit events, the total volume of events will also be
> dependent on the number of subscribers. If this component emits an event once
> every five seconds, but two projects subscribe to them, you'll effectively be
> receiving _two_ events every five seconds.

After allowing sufficient time to pass for new events to have been emitted by
the Noisy Neighbor, list the events for the `noisy-ned` project to confirm you
have subscribed correctly:

```shell
$ brig event list --project noisy-ned
```

Full coverage of `brig` commands is beyond the scope of this documentation, but
at this point,
[additional `brig` commands](https://docs.brigade.sh/topics/project-developers/brig/)
can be applied to monitor and manage the events.

## Contributing

The Brigade project accepts contributions via GitHub pull requests. The
[Contributing](CONTRIBUTING.md) document outlines the process to help get your
contribution accepted.

## Support & Feedback

We have a slack channel!
[Kubernetes/#brigade](https://kubernetes.slack.com/messages/C87MF1RFD) Feel free
to join for any support questions or feedback, we are happy to help. To report
an issue or to request a feature open an issue
[here](https://github.com/brigadecore/brigade-noisy-neighbor/issues)

## Code of Conduct

Participation in the Brigade project is governed by the
[CNCF Code of Conduct](https://github.com/cncf/foundation/blob/master/code-of-conduct.md).
