defmodule ChatElixir.ChatGPT.ApiTest do
  use ChatElixir.DataCase, async: true

  alias ChatElixir.ChatGPT.Api

  test "chat_completion" do
    messages = [
      %{
        "role" => "user",
        "content" => "Using html. This is short test"
      }
    ]

    assert {:ok, text} =
             Api.chat_completion(messages, :"gpt-4", %{
               "max_tokens" => 100
             })

    assert String.contains?(text, "</")
  end

  test "stream_chat_completion" do
    messages = [
      %{
        "role" => "user",
        "content" => "Using html. This is short test"
      }
    ]

    stream =
      Api.stream_chat_completion(messages, :"gpt-4", %{
        "max_tokens" => 100
      })

    assert [_ | _] = Enum.filter(stream, &String.contains?(&1, "</"))
  end

  test "image" do
    assert {:ok, url} = Api.image("This is a test")
    assert String.contains?(url, "https://")
  end

  test "embeddings" do
    assert [embedding | _] = Api.embeddings("This is a test")
    assert is_number(embedding)
  end
end
