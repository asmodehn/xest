defmodule XestKraken.Adapter.Cache do
  use Nebulex.Cache,
    otp_app: :xest_kraken,
    adapter: Nebulex.Adapters.Local
end
