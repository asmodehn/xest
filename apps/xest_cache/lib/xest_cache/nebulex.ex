defmodule XestCache.Nebulex do
  use Nebulex.Cache,
    otp_app: :xest_cache,
    adapter: Nebulex.Adapters.Local
end
