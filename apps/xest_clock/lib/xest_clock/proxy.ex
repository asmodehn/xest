defmodule XestClock.Proxy do
  @docmodule """
    This module deals with a simulated clock, wrapping the original (remote) clock.

    The simulated clock is useful to store the detected offset, to avoid recomputing it on each call.

  """

  alias XestClock.Clock

  @enforce_keys [:remote]
  defstruct remote: nil,
            offset: nil

  @typedoc "XestClock.Clock struct"
  @type t() :: %__MODULE__{
          remote: Clock.t(),
          offset: Timestamp.t()
        }

  @spec new(Clock.t()) :: t()
  def new(%Clock{} = clock) do
    %__MODULE__{
      remote: clock
    }
  end

  @doc """
    with_offset computes offset compared with a reference clock
  """
  def compute_offset(%__MODULE__{} = proxy, %Clock{} = reference) do
    offset =
      reference
      |> Clock.offset(proxy.remote)
      # because one time is enough to compute offset
      |> Enum.at(0)

    %{proxy | offset: offset}
  end
end
