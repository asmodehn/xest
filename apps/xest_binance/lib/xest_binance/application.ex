defmodule XestBinance.Config do
  use Vapor.Planner
  # Ref : https://github.com/keathley/vapor#readme
  dotenv()

  config :binance,
         file(
           Application.get_env(:binance, :config_file),
           [
             {:apikey, "apikey", required: false},
             {:secret, "secret", required: false},
             {:endpoint, "endpoint"}
           ]
         )
end

defmodule XestBinance.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    config = Vapor.load!(XestBinance.Config)

    children = [
      # Starting main Binance Server
      {XestBinance.Server, name: XestBinance.Server, endpoint: config.binance.endpoint},

      # Starting authenticated Binance Server for user account

      {XestBinance.Authenticated,
       name: XestBinance.Authenticated,
       apikey: config.binance.apikey,
       secret: config.binance.secret,
       endpoint: config.binance.endpoint},

      # Starting main Exchange Agent managing retrieved state
      {XestBinance.Exchange, name: XestBinance.Exchange},
      # Starting main Account Agent managing retrieved state
      {XestBinance.Account, name: XestBinance.Account}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: XestBinance.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
