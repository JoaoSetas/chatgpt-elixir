defmodule ChatElixirWeb.PageController do
  use ChatElixirWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
