defmodule XestBinance.Config do
  use Vapor.Planner
  # Ref : https://github.com/keathley/vapor#readme
  dotenv()

  config :xest_binance,
         file(
           Application.get_env(
             :xest_binance,
             :config_file,
             Path.expand("../../default.toml", Path.expand(__DIR__))
           ),
           [
             {:apikey, "apikey", required: false},
             {:secret, "secret", required: false},
             {:endpoint, "endpoint"}
           ]
         )
end
