defmodule XestBinance.Adapter.Cache do
  use Nebulex.Cache,
    otp_app: :xest_binance,
    adapter: Nebulex.Adapters.Local
end
