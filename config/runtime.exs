import Config
require Hammox

if config_env() == :test do
  # We want to prevent using actual apikey for tests
  # -> use preregistered cassettes instead
  config :binance,
    config_file: Path.expand("../test/integration_config.toml", Path.expand(__DIR__))

  # common mock for any app in umbrella.
  Hammox.defmock(DateTimeMock, for: Xest.DateTime.Behaviour)
  config :xest, date_time_module: DateTimeMock
else
  config :binance,
    config_file: System.user_home!() <> "/.config/xest/binance.toml"
end

# TODO : mix task to create config
