# XestClock

This is a library dealing with time, to help Xest server synchronise with servers in any region of the world.

These remote servers will share timestamped data, that is considered immutable, and these should be used as a base
upon which to build Xest logic.

However, the concept of monotonic time, timestamps, events are somewhat universal, so we should build some logic 
to help with time & events management in Xest.

Usually the timezone is unspecified (unix time), but could be somewhat deduced...

The goal is for this library to be the only one dealing with time concerns, in a stable and sustainable fashion, to free other apps from this burden.


## Demo

```bash
$ elixir example/worldclockapi.exs
```

## Livebook

A Demo.livemd is also there for you to play around with and visualize the precision evolution overtime.

```shell
$ livebook server --port 4000
```


## Roadmap

- [X] Clock as a Stream of Timestamps (internally integers for optimization)
- [X] Clock with offset, used to simulate remote clocks locally.
- [X] Clock Proxy to simulate a remote clock locally with `monotonic_time/1` client function
- [ ] take multiple remote clock measurement in account when computing offset & skew. maybe remove outliers...
- [ ] some clever way to improve error overtime ? PID controller of some sort (maybe reversed) ?

## Later, maybe ?

- erlang timestamp integration
- Tempo integration
- Generic Event Stream

