defmodule XestClock.Time.Derivatives do
  @moduledoc """
    a module to manage offsets compared to a local clock
  """

  # hiding Elixir.System to make sure we do not inadvertently use it
  alias XestClock.System

  alias XestClock.Time
  alias XestClock.Stream.Timed

  @enforce_keys [:unit, :last_local, :prop]
  defstruct unit: nil,
            last_local: nil,
            prop: nil,
            # initial values that make sense for derivative of time values
            derv: {0.0, 0.0},
            intg: {0.0, 0.0}

  @typedoc "TimeValue struct"
  @type t() :: %__MODULE__{
          unit: System.time_unit(),
          last_local: XestClock.Stream.Timed.LocalStamp.t(),
          # every value here has an associated error,
          # that is kept through the various computations
          # TODO : Measurement protocol instead.
          prop: Time.Value.t(),
          derv: {float(), float()},
          intg: {float(), float()}
        }

  def new(%Time.Value{} = tv, %Timed.LocalStamp{} = lts) do
    %__MODULE__{
      unit: tv.unit,
      last_local: lts,
      prop: Time.Value.diff(tv, Timed.LocalStamp.system_time(lts))
    }
  end

  def new(%Time.Value{} = tv, %Timed.LocalStamp{} = lts, %__MODULE__{} = last_derivatives)
      when tv.unit == last_derivatives.unit do
    drvs = new(tv, lts)

    # TODO : extract the offset computation outside
    # -> only keep derivative here (not error calculation)
    drvs_delta = Time.Value.diff(drvs.prop, last_derivatives.prop)
    drvs_sum = Time.Value.sum(drvs.prop, last_derivatives.prop)

    time_interval = Timed.LocalStamp.elapsed_since(lts, last_derivatives.last_local)

    # duplicated timestamp ?
    # Note : we are ignoring the timeinterval error here for simplicity.
    derv =
      if time_interval.value == 0 do
        # just reuse old values  # TODO : recomputing feasible ?
        last_derivatives.derv
      else
        # Note : time interval > 1

        deriv(drvs_delta, time_interval)
      end

    intg =
      if time_interval.value == 0 do
        # just reuse old values  # TODO : recomputing feasible ??
        last_derivatives.intg
      else
        integ(drvs_sum, time_interval)
      end

    %{drvs | derv: derv, intg: intg}
  end

  def compute(enum) do
    Stream.transform(enum, nil, fn
      {%Time.Value{} = tv, %Timed.LocalStamp{} = lts}, nil ->
        offset = new(tv, lts)
        # TODO : should we replace the actual value here ??
        {[{tv, lts, offset}], offset}

      {%Time.Value{} = tv, %Timed.LocalStamp{} = lts}, %__MODULE__{} = offset ->
        new_offset = new(tv, lts, offset)
        {[{tv, lts, new_offset}], new_offset}
    end)
  end

  def delta(%__MODULE__{} = new_deriv, %__MODULE__{} = last_deriv) do
    %__MODULE__{
      unit: new_deriv.unit,
      last_local: new_deriv.last_local,
      prop: Time.Value.diff(new_deriv.prop, last_deriv.prop),
      derv: new_deriv.derv - last_deriv.derv,
      # difference of derivative is derivative of difference
      intg: new_deriv.intg - last_deriv.intg
      # difference of integral is integral of difference
    }
  end

  # TODO : maybe merge with elapsed_since to only manage localtimestamp in denominator

  @spec deriv(t(), t()) :: {float, float}
  def deriv(%Time.Value{} = tv_num, %Time.Value{} = tv_den)
      # Note we explicitly ignore error on denominator (coming from local timestamp -> no error)
      when tv_den.value != 0 and tv_den.error == 0.0 do
    if System.convert_time_unit(1, tv_num.unit, tv_den.unit) < 1 do
      # invert conversion to avoid losing precision
      if tv_num.value == 0 do
        # 0 special case to no break arithmetic on error computation
        {0.0, 0.0}
      else
        val = tv_num.value / Time.Value.convert(tv_den, tv_num.unit).value

        {
          val,
          # x = a/b => max relative error in x = max relative error in a + max relative error in b
          # => error in x =  x * relative error in a + 0
          val * (tv_num.error / tv_num.value)
        }
      end
    else
      if tv_num.value == 0 do
        # 0 special case to no break arithmetic on error computation
        {0.0, 0.0}
      else
        val = Time.Value.convert(tv_num, tv_den.unit).value / tv_den.value

        {
          val,
          # x = a/b => max relative error in x = max relative error in a + max relative error in b
          val * (tv_num.error / tv_num.value)
        }
      end
    end
  end

  # TODO
  def integ(%Time.Value{} = tv, %Time.Value{} = tv_elapsed) do
    if System.convert_time_unit(1, tv.unit, tv_elapsed.unit) < 1 do
      # invert conversion to avoid losing precision
      val = tv.value * 0.5 * Time.Value.convert(tv_elapsed, tv.unit).value

      {
        val,
        # x = a * b => max relative error in x = max relative error in a + max relative error in b
        # => error in x =  x * relative error in a + 0
        val * (tv.error / tv.value)
      }
    else
      val = Time.Value.convert(tv, tv_elapsed.unit).value * 0.5 * tv_elapsed.value

      {
        val,
        # x = a/b => max relative error in x = max relative error in a + max relative error in b
        val * (tv.error / tv.value)
      }
    end
  end
end
