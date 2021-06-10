defmodule Xest.Clock.Proxy do
  @type clock() :: (() -> DateTime.t())
  @type skew() :: Timex.Duration.t()

  # no remote, only local by default
  defstruct remote_clock: nil,
            # no previous retrieval
            requested_on: nil,
            # valid forever by default.
            ttl: nil,
            # no skew with local by default
            skew: Timex.Duration.from_microseconds(0)

  @type t() :: %__MODULE__{
          remote_clock: clock(),
          requested_on: DateTime.t(),
          ttl: Timex.Duration.t(),
          skew: Timex.Duration.t()
        }

  @spec new(clock()) :: t()
  def new(remote_clock \\ nil) do
    %__MODULE__{
      # nil denote no remote (local only)
      remote_clock: remote_clock
    }
  end

  @spec ttl(t(), Timex.Duration.t()) :: t()
  def ttl(%__MODULE__{} = proxy, ttl) do
    proxy |> Map.put(:ttl, ttl)
  end

  @spec expired?(t()) :: boolean()
  def expired?(%__MODULE__{requested_on: nil, ttl: ttl}) do
    # ttl == nil means state cannot expire.
    # ttl not nil with no past retrieval -> already expired
    ttl != nil
  end

  def expired?(proxy) do
    # only request local utc_now when actually needed
    expired?(proxy, Xest.DateTime.utc_now())
  end

  @spec expired?(t(), DateTime.t()) :: boolean()
  def expired?(%__MODULE__{requested_on: nil, ttl: ttl}, _) do
    # ttl == nil means state cannot expire.
    # ttl not nil with no past retrieval -> already expired
    ttl != nil
  end

  def expired?(%__MODULE__{ttl: nil} = proxy, now) do
    proxy.requested_on > now
  end

  def expired?(%__MODULE__{ttl: ttl} = proxy, now) do
    Timex.add(proxy.requested_on, ttl) < now
  end

  @spec retrieve(t(), DateTime.t()) :: t()
  def retrieve(proxy, requested_on \\ Xest.DateTime.utc_now())

  def retrieve(%__MODULE__{remote_clock: nil} = proxy, requested_on) do
    proxy
    |> Map.put(:requested_on, requested_on)

    # don't change the skew, it should remain default value (duration 0 us)
  end

  def retrieve(%__MODULE__{remote_clock: remote_clock} = proxy, requested_on) do
    {duration, srv_time} = Timex.Duration.measure(remote_clock)

    lcl_time =
      Timex.add(
        requested_on,
        duration |> Timex.Duration.scale(0.5)
      )

    proxy
    |> Map.put(:requested_on, requested_on)
    |> Map.put(:skew, skew(srv_time, lcl_time))
  end

  @spec skew(DateTime.t(), DateTime.t()) :: skew()
  defp skew(reference, local) do
    # skew as a diff to be able to simply add the skew
    # onto local time later when estimating remote...
    Timex.Duration.from_microseconds(Timex.diff(reference, local, :microseconds))
  end
end
