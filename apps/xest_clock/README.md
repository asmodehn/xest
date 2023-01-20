# XestClock

This is a library dealing with time, to help Xest server synchronise with servers in any region of the world.

These remote servers will share timestamped data, that is considered immutable, and these should be used as a base
upon which to build Xest logic.

However, the concept of monotonic time, timestamps, events are somewhat universal, so we should build some logic 
to help with time & events management in Xest.

Usually the timezone is unspecified (unix time), but could be somewhat deduced...

The goal is for this library to be the only one dealing with time concerns, to free other apps from this burden.


## Demo

```bash
$ elixir example/worldclockapi.exs
```


## Roadmap

- [X] Clock as a Stream of Timestamps (internally integers for optimization)
- [X] Clock with offset, used to simulate remote clocks locally.
- [X] NaiveDateTime integration
- [X] Clock -> StreamClock, XestClock -> Clock
- [ ] Ticker to hold a Clock struct (map with possibly multiple streamclocks) to match usual "clock" semantics
- [ ] Some familiar interface ("use" / protocol, etc.) to use Ticker from a xest_connector

## Later, maybe ?

- remote clock locally-estimated response timestamp (mid-flight)
- erlang timestamp integration
- Tempo integration
- Clock with offset and skew / linear map ?
- Clock with error anticipation and correction
- Generic Event Stream

