defmodule ChatElixir.ChatGPT.ApiTest do
  use ChatElixir.DataCase, async: true

  alias ChatElixir.ChatGPT.Api

  test "completion" do
    assert text = Api.completion("This is a test")
    assert String.length(text) > 0
  end

  test "stream_completion" do
    stream = Api.stream_completion("This is a test")
    assert steam = Enum.take(stream, 1) |> List.first()
    assert String.length(steam) > 0
  end

  test "image" do
    assert url = Api.image("This is a test")
    assert String.contains?(url, "https://")
  end

  test "embeddings" do
    assert [embedding | _] = Api.embeddings("This is a test")
    assert is_number(embedding)
  end
end
