import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :xest_web, XestWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "H/E5uucRKyj8KYeafvCxK0XCPa0wjBZCp+RWctYMFz+pzNCiSm+fk7Fd/SIAlGj6",
  server: false

# In test we don't send emails.
config :hello_web, HelloWeb.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# NOT YET
## Config for Commanded in-memory eventstore for test
# config :commanded, event_store_adapter: Commanded.EventStore.Adapters.InMemory
# config :commanded, Commanded.EventStore.Adapters.InMemory, serializer: Commanded.Serialization.JsonSerializer
