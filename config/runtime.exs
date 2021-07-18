import Config
require Hammox

if config_env() == :test do
  # We want to prevent using actual apikey for tests
  # -> use preregistered cassettes instead
  config :xest_binance,
    config_file: Path.expand("../test/integration_binance.toml", Path.expand(__DIR__))

  # TODO : a better way ?  maybe via mix test options ?
  #    # TMP for recording
  #  config :xest_kraken,
  #    config_file: System.user_home!() <> "/.config/xest/kraken.toml"
else
  config :xest_binance,
    config_file: System.user_home!() <> "/.config/xest/binance.toml"

  config :xest_kraken,
    config_file: System.user_home!() <> "/.config/xest/kraken.toml"
end

# TODO : mix task to create config
