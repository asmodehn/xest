import Config

# In tests, we do not want a connection to actual exchange servers
if config_env() != :test do
  config :xest_binance,
    config_file: System.user_home!() <> "/.config/xest/binance.toml"

  config :xest_kraken,
    config_file: System.user_home!() <> "/.config/xest/kraken.toml"
else
  # Uncomment these when you need to access the account to create cassettes.
  # WARNING: in this case a connection to your actual account on the server
  # is made. you will want to clean up the cassette afterwards

  #  config :xest_binance,
  #    config_file: System.user_home!() <> "/.config/xest/binance.toml"

  #  config :xest_kraken,
  #    config_file: System.user_home!() <> "/.config/xest/kraken.toml"
end

# TODO : mix task to create config
