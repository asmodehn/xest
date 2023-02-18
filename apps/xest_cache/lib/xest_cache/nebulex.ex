defmodule XestCache.Nebulex do
  @moduledoc false

  use Nebulex.Cache,
    otp_app: :xest_cache,
    adapter: Nebulex.Adapters.Local
end
