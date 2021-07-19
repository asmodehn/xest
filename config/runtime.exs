import Config
require Hammox

# we do not want automated connection to actual exchange servers by default
if config_env() != :test do
  config :xest_binance,
    config_file: System.user_home!() <> "/.config/xest/binance.toml"

  config :xest_kraken,
    config_file: System.user_home!() <> "/.config/xest/kraken.toml"
end

# TODO : mix task to create config
