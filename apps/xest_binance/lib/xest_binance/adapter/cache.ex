defmodule XestBinance.Adapter.Cache do
  use Nebulex.Cache,
    otp_app: :xest_binance,
    adapter: Nebulex.Adapters.Local
end

# TODO : merge cache into / with/ along exchange and account processes, so their lifetime
# are linked...
