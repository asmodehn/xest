# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of Mix.Config.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
use Mix.Config
# TODO : migrate to Elixir.Config
# cf. https://hexdocs.pm/elixir/Config.html#module-migrating-from-use-mix-config

config :xest_web,
  generators: [context_app: :xest]

# Configures the endpoint
config :xest_web, XestWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "1sIf93yrT+BUBqpuKb2UdRf+wBGtPMz2MNFllhznIrH3dQo2HGHU+z/PJhVKREFj",
  render_errors: [view: XestWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Xest.PubSub,
  live_view: [signing_salt: "e9m51YXq"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :xest,
  # TODO : deprecate and remove this
  # setup adapter for binance genserver for authenticated requests
  binance_authenticated: XestBinance.Authenticated

# For clarity, but this may not need to be explicited here...
# config  :xest_binance,
#        adapter: XestBinance.Adapter.Binance

config :xest_kraken,
  adapter: XestKraken.Adapter.Krakex,
  exchange: XestKraken.Exchange

config :xest_web,
  binance_exchange: XestBinance.Exchange,
  binance_account: XestBinance.Account

config :xest,
  kraken_exchange: XestKraken.Exchange,
  binance_exchange: XestBinance.Exchange

# For clarity, but this may not need to be explicited here...
# config :xest_web,
#  exchange: Xest.Exchange

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
