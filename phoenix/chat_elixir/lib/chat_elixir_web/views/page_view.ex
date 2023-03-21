defmodule ChatElixirWeb.PageView do
  use ChatElixirWeb, :view

  def test() do
    raw(ChatElixir.ChatGPT.Api.completion("how to plant corn"))
  end
end
