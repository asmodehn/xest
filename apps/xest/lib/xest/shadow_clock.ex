defmodule Xest.ShadowClock do
  @moduledoc """
  A lazy shadow clock, with micro seconds (estimated) precision, following a remote clock.
  This is useful when requesting clock time is expensive.
  """

  @enforce_keys [:local_clock, :remote_clock]
  defstruct last_remote_datetime: nil,
            last_remote_request: nil,
            last_remote_response: nil,
            local_clock: nil,
            remote_clock: nil

  @typedoc "A clock, callable (impure) function returning a DateTime"
  @type clock() :: (() -> DateTime.t())

  @typedoc "A shadow clock, estimate an actual remote clock, expensive to retrieve"
  @type t() :: %__MODULE__{
          # these three are just a record of a past event.
          last_remote_datetime: DateTime.t() | nil,
          last_remote_request: DateTime.t() | nil,
          last_remote_response: DateTime.t() | nil,
          local_clock: clock(),
          remote_clock: clock()
        }

  @spec new(clock(), clock()) :: t()
  def new(remote_utc_now, utc_now \\ &Timex.now/0) do
    %Xest.ShadowClock{
      local_clock: utc_now,
      remote_clock: remote_utc_now
    }
  end

  @spec now(t()) :: DateTime.t()
  def now(%Xest.ShadowClock{last_remote_datetime: nil} = clock) do
    clock.local_clock.()
  end

  def now(
        %Xest.ShadowClock{
          local_clock: local_clock,
          last_remote_datetime: remote_dt,
          last_remote_request: remote_req
        } = clock
      )
      when remote_dt != nil do
    estimated_local_reqrep_time = Timex.add(remote_req, half_time_of_flight(clock))
    offset = Timex.diff(remote_dt, estimated_local_reqrep_time)
    Timex.add(local_clock.(), Timex.Duration.from_microseconds(offset))
  end

  @spec half_time_of_flight(t()) :: Timex.Duration.t()
  defp half_time_of_flight(%Xest.ShadowClock{
         last_remote_request: remote_req,
         last_remote_response: remote_rep
       }) do
    Timex.Duration.from_microseconds(div(Timex.diff(remote_rep, remote_req), 2))
  end

  @spec update(t()) :: t()
  def update(%Xest.ShadowClock{last_remote_datetime: nil} = clock) do
    remote_request = clock.local_clock.()
    remote_datetime = clock.remote_clock.()

    %Xest.ShadowClock{
      clock
      | last_remote_datetime: remote_datetime,
        last_remote_request: remote_request,
        last_remote_response: clock.local_clock.()
    }
  end

  def update(%Xest.ShadowClock{last_remote_response: remote_response} = clock) do
    # TMP some hard coded deadline
    if Timex.diff(clock.local_clock.(), remote_response) > Timex.Duration.from_time(~T[00:01:00]) do
      clock
      |> Map.put(:last_remote_datetime, nil)
      |> update()
    else
      clock
    end
  end
end
