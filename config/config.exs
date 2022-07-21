# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of Mix.Config.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Configures the endpoint
config :xest_web, XestWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "1sIf93yrT+BUBqpuKb2UdRf+wBGtPMz2MNFllhznIrH3dQo2HGHU+z/PJhVKREFj",
  render_errors: [view: XestWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Xest.PubSub,
  live_view: [signing_salt: "e9m51YXq"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.0",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/xest_web/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.1.6",
  default: [
    args: ~w(
    --config=tailwind.config.js
    --input=css/app.css
    --output=../priv/static/assets/app.css
  ),
    cd: Path.expand("../apps/xest_web/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :xest,
  kraken_exchange: XestKraken.Exchange,
  kraken_clock: XestKraken.Clock,
  kraken_account: XestKraken.Account,
  binance_exchange: XestBinance.Exchange,
  binance_clock: XestBinance.Clock,
  binance_account: XestBinance.Account

config :xest_binance, XestBinance.Adapter.Cache,
  # When using :shards as backend
  # backend: :shards,
  # GC interval for pushing new generation: 1 hrs
  gc_interval: :timer.hours(1),
  # Max 1 thousand entries in cache
  max_size: 1_000,
  # Max 2 MB of memory
  allocated_memory: 2_000_000,
  # GC min timeout: 5 sec
  gc_cleanup_min_timeout: :timer.seconds(5),
  # GC max timeout: 15 min
  gc_cleanup_max_timeout: :timer.minutes(15)

config :xest_kraken, XestKraken.Adapter.Cache,
  # When using :shards as backend
  # backend: :shards,
  # GC interval for pushing new generation: 1 hrs
  gc_interval: :timer.hours(1),
  # Max 1 thousand entries in cache
  max_size: 1_000,
  # Max 2 MB of memory
  allocated_memory: 2_000_000,
  # GC min timeout: 5 sec
  gc_cleanup_min_timeout: :timer.seconds(5),
  # GC min timeout: 15 min
  gc_cleanup_max_timeout: :timer.minutes(15)

config :xest_kraken,
  exchange: XestKraken.Exchange

# TODO : deprecate these, use from :xest app namespace instead.
config :xest_web,
  binance_exchange: XestBinance.Exchange

# For clarity, but this may not need to be explicited here...
# config :xest_web,
#  exchange: Xest.Exchange

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
