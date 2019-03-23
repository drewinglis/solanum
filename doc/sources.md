Source Configuration
====================

Solanum has a number of metrics sources which can be used for local monitoring.
All sources support the following configuration parameters:

- `type`

  This is required for every source.

- `mode`

  May be provided to override the _mode_ the source operates in, which is
  typically a specific system type like `linux`, `darwin`, `bsd`, etc.

- `period` (default: `60`)

  The scheduler will collect metrics from the source every time this duration in
  seconds passes, plus a bit of jitter.

- `attributes`

  May be provided as a nested map of attributes to add to each event from this
  source. These take precedence over any defaults in the config or attributes
  provided on the command-line.


## cpu

This source measures processor utilization across the entire machine. It may
also provide per-core and per-state measurements if more detailed resolution is
desired. The main event reported is `cpu usage` with the value as the percentage
of time the cpu spent working.

- `per-core`

  If true, the source will report events with the usage of each core in addition
  to full-cpu usage. These events will have a `core` attribute with the measured
  core number.

- `per-state`

  If true, the source will report events with the percentage of time the cpu
  spent in each state, such as `user`, `nice`, `system`, `iowait`, `idle`, etc.
  Can be combined with `per-core` to show per-core-states.

- `usage-states`

  A map of state names to thresholds. If the value in a usage event meets or
  exceeds the value of a threshold, the event's `state` will be set to match.


## disk-space

The `disk-space` source measures filesystem space usage. It reports a
`disk space usage` event for each mounted filesystem that appears to correspond
to a block device which gives the percentage of space being used.

- `usage-states`

  A map of state names to thresholds. If the value in a usage event meets or
  exceeds the value of a threshold, the event's `state` will be set to match.


## disk-stats

The `disk-stats` source measures block device IO utilization. It reports a
collection of metrics including the number of bytes read and written, the time
spent on those operations, and overall IO activity.

- `devices`

  A list of block devices to measure. By default the source will measure any
  devices matching `sd[a-z]` or `xvd[a-z]`.

- `detailed`

  If true, the source will report several additional IO metrics such as counts
  of the read and write requests which have completed or been merged.


## http

**WARNING:** Currently non-functional in native binaries - see
[#8](https://github.com/greglook/solanum/issues/8).

This source makes requests to a local HTTP endpoint and validates properties
about the response. This is useful for triggering health-check APIs and
verifying that services are running properly. The source produces two events,
`http url time` and `http url health`.

- `url` (required)

  The URL to call. This _should_ be a local service running on the host, but is
  not forced to be.

- `label` (default: same as `url`)

  Overrides the `label` field in the sent events with a more human-friendly
  name. Usually this is set to the name of the service being checked.

- `timeout` (default: `1000`)

  How many milliseconds to wait for a response before an error is returned.

- `response-checks`

  A sequence of validations to run against the HTTP response. By default, this
  just asserts that the response code was `200`. See the
  [response checks](#http-response-checks) section below.

- `record-fields`

  A map of event attributes to data paths to forward in each event. For example,
  an entry of `foo: bar` would set the event attribute `foo` to the value of
  `bar` in the response body. This may also be nested, so `foo: [bar, qux]`
  would look up the value of `qux` inside the map at `bar` in the response.

### HTTP Response Checks

Each response check defines a rule used to determine whether the HTTP endpoint
is healthy or not. Checks may be one of three types:

- `status`

  This check evaluates whether the HTTP response code matches a set of
  acceptable values. A single code may be given as a `value` or a list may be
  provided as `values`.

- `pattern`

  This check matches a regular expression in `pattern` against the _text body_
  of the response. If the expression matches, the check passes.

- `data`

  This check tries to parse the response body as EDN or JSON and determines
  whether a value inside the response matches a set of acceptable values. The
  value is resolved by looking up the check `key` using the `record-fields`
  logic above, then checked against `value` or `values` in the check. If the
  value is not acceptable or the body cannot be parsed, the check fails.


## load

This source measures process statistics across the entire host. It reports a
`process load` event with the one-minute load average, as well as
`process total` and `process running` events giving the number of processes and
how many are active.

- `load-states`

  A map of state names to thresholds. If the value of the load event exceeds the
  value of a threshold, the event's `state` will be set to match.


## memory

This source measures the system memory utilization. It reports a `memory usage`
event with the percentage of the total available RAM used, as well as events
measuring the proportion of that which is dedicated to buffers and operating
system caches. If the machine has a swap partition, it will also report
`swap usage`.

- `usage-states`

  A map of state names to thresholds. If the value of the usage event exceeds the
  value of a threshold, the event's `state` will be set to match.

- `swap-states`

  A map of state names to thresholds. As above, but for swap usage.


## network

This source measures network interface metrics. By default, it reports events
for each interface's received and transmitted bytes and packets. It may also
report more detailed metrics if configured. Each measurement is prefixed with
`net io ...` and includes an `interface` attribute.

- `interfaces`

  An explicit list of network interfaces to measure. By default the source will
  measure all interfaces.

- `ignore`

  A list of network interfaces to ignore. By default, this includes only the
  loopback device `lo`.

- `detailed`

  If true, the source will report additional network metrics such as the number
  of errors seen, packets dropped, compressed and multicast packets, and more.


## process

This source watches specific processes running on the host to monitor whether
they are alive. The source reports a `process count` of all running processes
which match the given pattern.

It also reports two measures of the matched processes' memory usage. The
`process resident-set bytes` gives the actual physical memory held active by the
process, while the `process virtual-memory bytes` shows the total memory
allocated, some of which may be unused or paged out to disk.

- `pattern` (required)

  A regular expression to match the processes being watched. If more than one
  process matches, the events record the _aggregate_ statistics of all of them.

- `label` (default: same as `pattern`)

  Overrides the `label` field in the sent events with a more human-friendly
  name. Usually this is set to the name of the process being watched.

- `user`

  If given, restricts which user must own the running processes in order to
  match them.

- `min-states`

  A map of state names to thresholds. If the count of matched processes is under
  the value of a threshold, the event's `state` will be set to match. Use this
  to ensure _at least_ a certain number of processes are running. Usually takes
  the form of `critical: 0`.

- `max-states`

  A map of state names to thresholds. If the count of matched processes is over
  the value of a threshold, the event's `state` will be set to match. Use this
  to ensure that _no more than_ a certain number of processes are running.


## shell

This source provides an escape hatch if some metrics collection is not supported
directly by the daemon. It periodically executes a shell command and interprets
the response as metrics events.

- `command` (required)

  A command to execute with the shell in order to collect the metrics data.

- `shell` (default: `$SHELL`)

  The shell to use to execute the command.

The command is expected to return some output which conforms to the following
line protocol:

```
<service>\t<metric>[\t<attribute>=<value>][\t...]
```

The first entry on the line should be the measurement's service name, followed
by a tab `\t` character, then the numeric metric value. The value may be an
integer or a floating-point number. Following that may be zero or more
attribute-value pairs, similarly separated by tabs.


## tcp

This source tests that a local port is open and accepting TCP connections. It
reports a single event, `tcp socket open` with a metric and state of `1`/`ok` if
the socket is open, or `0`/`critical` if not.

- `port` (required)

  The TCP port to check.

- `host` (default: `localhost`)

  The host to connect to. This should _usually_ be localhost, though in some
  cases a service may only bind to specific interfaces.

- `label` (default: same as `port`)

  Overrides the `port` field in the sent events with a more human-friendly
  name. Usually this is set to the name of the process or protocol the port is
  for.


## test

This source is a simple generator for exercising Solanum. It generates test
events with a few bits of random variance.

- `min-count` (default: `1`)

  Generate at least this many events each time the source is collected.

- `max-count` (default: `1`)

  Generate at most this many events each time the source is collected.


## uptime

This source measures how long the host has been running. It reports a single
`uptime` event giving the lifetime of the host in seconds.
