defmodule XestClock do
  # TODO: __using__ so that a connector can use XestClock,
  # and only indicate how to retrieve the current time (web request or so),
  # To get a gen_server ticking as a proxy of the remote clock.
  # The stream machinery should be hidden from the user for simple usage.

  @moduledoc """

  XestClock manages local and remote clocks as either stateless streams or stateful processes,
  dealing with monotonic time.

  The stateful processes are simple gen_servers manipulating the streams,
  but they have the most intuitive usage.

  The streams of timestamps are the simplest to exhaustively test,
  and can be used no matter what your process architecture is for your application.

  This package is useful when you need to work with remote clocks, which cannot be queried very often,
  yet you still need some robust tracking of elapsed time on a remote system,
  by leveraging your local system clock, and assuming remote clocks are deviating only slowly from your local system clock...

  Sensible defaults have been set in child_specs for the Clock Server, and you should always use it with a Supervisor,
  so that you can rely on it being always present, even when there is bad network weather conditions.
  Calling XestClock.Server.start_link yourself, you will have to explicitly pass the Stream you want the Server to work with.
  """
end
