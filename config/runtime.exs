import Config

if config_env() == :test do
  config :binance,
    config_file: Path.expand("../test/integration_config.toml", Path.expand(__DIR__))
else
  config :binance,
    config_file: System.user_home!() <> "/.config/xest/binance.toml"
end

# TODO : mix task to create config
