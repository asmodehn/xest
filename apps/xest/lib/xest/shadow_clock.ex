defmodule Xest.ShadowClock do
  @docmodule """
  a shadow clock in micro seconds precision, following a remote clock...
  """

  @enforce_keys [:local_clock, :remote_clock]
  defstruct last_remote_dt_sample: nil,
            offset: nil,
            local_clock: nil,
            remote_clock: nil

  @typedoc "A clock, callable (impure) function returning a DateTime"
  @type clock() :: (() -> DateTime.t())

  @typedoc "A shadow clock, estimate an actual remote clock, expensive to retrieve"
  @type t() :: %__MODULE__{
          last_remote_dt_sample: DateTime.t() | nil,
          offset: integer() | nil,
          local_clock: clock(),
          remote_clock: clock()
        }

  @spec new(clock(), clock()) :: t()
  def new(remote_utc_now, utc_now \\ &Timex.now/0) do
    remote_now = remote_utc_now.()
    local_now = utc_now.()
    offset = Timex.diff(remote_now, local_now)

    %Xest.ShadowClock{
      last_remote_dt_sample: remote_now,
      offset: offset,
      local_clock: utc_now,
      remote_clock: remote_utc_now
    }
  end

  def now(%Xest.ShadowClock{} = clock) do
    # TODO : check if the last remote sample is too old...
    Timex.add(clock.local_clock.(), Timex.Duration.from_microseconds(clock.offset))
  end

  #  def delta(%Xest.ShadowClock{} = clock, local_dt) do
  #    Timex.diff(utc_now.() ,Timex.from_unix(server_time, :microseconds))
  #  end
  #
  #  def guess(local_dt) do
  #    Timex.add(local_dt, Timex.Duration.from_microseconds(state.server_time_skew_usec))
  #      |> IO.inspect
  #  end
end
