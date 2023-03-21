defmodule ChatElixir.ChatGPT.Api do

  def completion(text, options \\ %{}) do
    url = "https://api.openai.com/v1/completions"
    headers = [
      {"Authorization", "Bearer #{System.get_env("OPENAI_API_KEY")}"},
      {"Content-Type", "application/json"}
    ]
    default_options = %{
      "prompt" => "Create html content using bootstrap about #{text}:\n<",
      "model" => "text-davinci-003",
      "max_tokens" => 3500,
      "temperature" => 0.1,
      "top_p" => 1,
      "best_of" => 1,
      "frequency_penalty" => 0,
      "presence_penalty" => 0
    }

    options = Map.merge(default_options, options)

    body = Jason.encode!(options)
    {:ok, %HTTPoison.Response{status_code: 200, body: body}} = HTTPoison.post(url, body, headers, [timeout: 100_000, recv_timeout: 100_000])
    body = Jason.decode!(body)
    [%{"text" => response}|_] = body["choices"]

    "<" <> response
  end
end
