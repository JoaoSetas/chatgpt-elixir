defmodule ChatElixir.ChatGPT.ApiTest do
  use ChatElixir.DataCase, async: true

  alias ChatElixir.ChatGPT.Api

  test "chat_completion" do
    messages = [
      %{
        "role" => "user",
        "content" => "Using only html body make a simple page"
      }
    ]

    assert {:ok, text} =
             Api.chat_completion(messages, :"gpt-4-1106-preview", %{
               "max_tokens" => 1000
             })

    assert String.contains?(text, "</")
  end

  test "stream_chat_completion" do
    messages = [
      %{
        "role" => "user",
        "content" => "Using only html body make a simple page"
      }
    ]

    stream =
      Api.stream_chat_completion(messages, :"gpt-4-1106-preview", %{
        "max_tokens" => 1000
      })

    assert [_ | _] = Enum.filter(stream, &String.contains?(&1, "</"))
  end

  test "image" do
    assert {:ok, url} = Api.image("This is a test")
    assert String.contains?(url, "https://")
  end
end
