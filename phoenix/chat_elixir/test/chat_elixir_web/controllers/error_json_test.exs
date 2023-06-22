defmodule ChatElixirWeb.ErrorJSONTest do
  use ChatElixirWeb.ConnCase, async: true

  test "renders 404" do
    assert ChatElixirWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert ChatElixirWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
