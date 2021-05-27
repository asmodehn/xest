use Mix.Config

alias Hammox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :xest_web, XestWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# NOT YET
## Config for Commanded in-memory eventstore for test
# config :commanded, event_store_adapter: Commanded.EventStore.Adapters.InMemory
# config :commanded, Commanded.EventStore.Adapters.InMemory, serializer: Commanded.Serialization.JsonSerializer
