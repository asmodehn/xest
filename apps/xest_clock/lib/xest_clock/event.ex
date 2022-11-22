defmodule XestClock.Event do
  @moduledoc """
    This module deals with the structure of an event,
    which can also be a set of events, happening in no discernable order in time nor space location.

  The clock used to timestamp the event is a clock at (or as close as possible to) the origin of
    the event, to minimize timing error.

  However, these events only make sense for a specific origin (the origin of the knowledge of them occuring),
  that we reference via a single atom, to keep flexibility in what the client code can use it for.

  """

  require XestClock.Event.Local
  require XestClock.Event.Remote

  @type t() :: XestClock.Event.Local.t() | XestClock.Event.Remote.t()

  @spec local(any(), Clock.Timestamp.t()) :: t()
  defdelegate local(data, at), to: XestClock.Event.Local, as: :new

  @spec remote(any(), Clock.Timeinterval.t()) :: t()
  defdelegate remote(data, inside), to: XestClock.Event.Remote, as: :new

  # TODO : different structs for notice or retrieve could help us pick the correct implementation here...
  # Problem :timing and noticing are local (even for remote events... ???)

  #  @doc "wait for and return the next event, synchronously"
  #  def next(notice_or_retrieve, local_clock)
  #
  #  @doc "create a stream that will retrieve all further events, asynchronously"
  #  def stream(notice_or_retrieve, local_clock)
end
