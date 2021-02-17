defmodule XestWeb.BinanceViewTest do
  use XestWeb.ConnCase, async: true

  # When testing helpers, you may want to import Phoenix.HTML and
  # use functions such as safe_to_string() to convert the helper
  # result into an HTML string.
  # import Phoenix.HTML

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders binance.html" do
    assert render_to_string(
             XestWeb.BinanceView,
             "binance.html",
             %{status: %{"msg" => "binance_status"}}
           ) =~ "binance_status"
  end

end
