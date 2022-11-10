defmodule XestWeb.Router do
  use XestWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {XestWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", XestWeb do
    pipe_through :browser

    # keep that for overview dashboard
    get "/", PageController, :index

    # demos
    live "/democlock", ClockLive, :index
    live "/demoimage", ImageLive, :index

    # prototype pages
    live "/binance", BinanceLive, :index
    live "/binance/:symbol", BinanceTradesLive, :index
    live "/kraken", KrakenLive, :index

    # TODO : use verified routes with recent phoenix ??
    live "/status", StatusLive, :index
    live "/status/:exchange", StatusLive, :index

    #    live "/assets", AssetsLive, :index
    #    live "/assets/:symbol", AssetsLive, :index
    live "/assets/:exchange/", AssetsLive, :index
    #    live "/assets/:exchange/:symbol", AssetsLive, :index

    #    live "/markets/", MarketsLive, :index
    #    live "/markets/:symbol", MarketsLive, :index
    #
    #    live "/trades", TradesLive, :index
    #    live "/trades/:symbol", TradesLive, :index
    #    live "/trades/:exchange", TradesLive, :index
    #    live "/trades/:exchange/:symbol", TradesLive, :index

    # TODO live "/orders", OrdersLive

    # TODO live "/bots", BotsLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", XestWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: XestWeb.Telemetry
    end
  end
end
